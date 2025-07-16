// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "FPSCharacterManager.h"
#include "FPSCharacterManagerComponent.h"
#include "FPSCharacterInteractor.h"
#include "FPSCharacterTrainingEnvironment.h"
#include "FPSTargetActor.h"
#include "LearningAgentsPPOTrainer.h"
#include "LearningAgentsCommunicator.h"
#include "Kismet/GameplayStatics.h"
#include "FPSCharacter.h"
#include "Engine/Engine.h"
#include "AIController.h"
#include "LearningAgentsController.h"
#include "LearningAgentsEntitiesManagerComponent.h"

AFPSCharacterManager::AFPSCharacterManager()
{
	PrimaryActorTick.bCanEverTick = true;

	LearningAgentsManager = CreateDefaultSubobject<UFPSCharacterManagerComponent>(TEXT("Learning Agents Manager"));
}

void AFPSCharacterManager::BeginPlay()
{
	Super::BeginPlay();
	
	// Initialize the learning system
	InitializeAgents();
	InitializeManager();
}

void AFPSCharacterManager::InitializeAgents()
{
	// Get all FPSCharacter agents (including Blueprint-derived ones)
	TArray<AActor*> Agents;
	UGameplayStatics::GetAllActorsOfClass(GetWorld(), AFPSCharacter::StaticClass(), Agents);
	
	// Also try to find any Character-derived actors that might be blueprints
	TArray<AActor*> AllCharacters;
	UGameplayStatics::GetAllActorsOfClass(GetWorld(), ACharacter::StaticClass(), AllCharacters);
	
	// Filter characters to only include FPSCharacter and its derivatives
	for (AActor* Actor : AllCharacters)
	{
		if (AFPSCharacter* FPSChar = Cast<AFPSCharacter>(Actor))
		{
			if (!Agents.Contains(Actor)) // Avoid duplicates
			{
				Agents.Add(Actor);
			}
		}
	}

	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Found %d total characters in world"), AllCharacters.Num());
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Found %d FPSCharacter agents"), Agents.Num());
	
	// Log details about what we found
	for (int32 i = 0; i < AllCharacters.Num(); i++)
	{
		AActor* Actor = AllCharacters[i];
		AFPSCharacter* FPSChar = Cast<AFPSCharacter>(Actor);
		UE_LOG(LogTemp, Warning, TEXT("Character %d: %s (Class: %s) - FPSCharacter Cast: %s"), 
			i, 
			*Actor->GetName(), 
			*Actor->GetClass()->GetName(),
			FPSChar ? TEXT("SUCCESS") : TEXT("FAILED"));
	}

	for (AActor* Agent : Agents)
	{
		// Ensure the agent has a controller for movement input
		if (APawn* Pawn = Cast<APawn>(Agent))
		{
			AController* ExistingController = Pawn->GetController();
			if (!ExistingController)
			{
				// Create an AI controller for learning agents
				UWorld* World = GetWorld();
				if (World)
				{
					AAIController* NewController = World->SpawnActor<AAIController>();
					if (NewController)
					{
						NewController->Possess(Pawn);
						UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Created AIController for agent %s"), *Agent->GetName());
					}
					else
					{
						UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Failed to create AIController for agent %s"), *Agent->GetName());
					}
				}
			}
			else
			{
				UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Agent %s already has controller %s"), 
					*Agent->GetName(), *ExistingController->GetClass()->GetName());
			}
		}
		
		// Add agent to the Learning Agents Manager
		int32 AgentId = LearningAgentsManager->AddAgent(Agent);
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Added agent %s to manager with ID %d"), *Agent->GetName(), AgentId);
		
		// Initialize agent for learning (disable player input, prepare for AI control)
		if (AFPSCharacter* FPSChar = Cast<AFPSCharacter>(Agent))
		{
			// Reset character position and state for learning
			FPSChar->SetActorLocation(FPSChar->GetActorLocation());
			FPSChar->SetActorRotation(FPSChar->GetActorRotation());
			UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Initialized %s for learning"), *Agent->GetName());
		}
		
		// Make sure manager ticks first
		Agent->AddTickPrerequisiteActor(this);

		// If in inference mode, we could reset positions here if needed
		if (RunMode == EFPSCharacterManagerMode::Inference)
		{
			// For now, just log that we're in inference mode
			UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Agent %s initialized in inference mode"), *Agent->GetName());
		}
	}

	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Initialized %d character agents"), Agents.Num());
	
	if (Agents.Num() == 0)
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: No FPSCharacter agents found! Make sure to:"));
		UE_LOG(LogTemp, Error, TEXT("1. Place FPSCharacter (or Blueprint derived from FPSCharacter) actors in your level"));
		UE_LOG(LogTemp, Error, TEXT("2. Don't just set FPSCharacter as PlayerPawn - you need actual actors in the world"));
		UE_LOG(LogTemp, Error, TEXT("3. Check that your Blueprint inherits from FPSCharacter, not just Character"));
	}
}

void AFPSCharacterManager::InitializeManager()
{
	// Should neural networks be re-initialized
	const bool ReInitialize = (RunMode == EFPSCharacterManagerMode::ReInitialize);

	// Make Interactor Instance
	ULearningAgentsManager* ManagerPtr = LearningAgentsManager;
	Interactor = Cast<UFPSCharacterInteractor>(ULearningAgentsInteractor::MakeInteractor(
		ManagerPtr, UFPSCharacterInteractor::StaticClass(), TEXT("FPSCharacter Interactor")));
	if (Interactor == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Failed to make interactor object."));
		return;
	}
	Interactor->TargetActor = TargetActor;
	LearningAgentsInteractorBase = Interactor;

	// Warn if neural networks are not set
	if (EncoderNeuralNetwork == nullptr || PolicyNeuralNetwork == nullptr || 
		DecoderNeuralNetwork == nullptr || CriticNeuralNetwork == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: One or more neural networks are not set."));
		return;
	}

	// Make Policy Instance
	ULearningAgentsInteractor* InteractorPtr = Interactor;
	Policy = ULearningAgentsPolicy::MakePolicy(
		ManagerPtr, InteractorPtr, ULearningAgentsPolicy::StaticClass(), TEXT("FPSCharacter Policy"), 
		EncoderNeuralNetwork, PolicyNeuralNetwork, DecoderNeuralNetwork, 
		ReInitialize, ReInitialize, ReInitialize, PolicySettings, RandomSeed);
	if (Policy == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Failed to make policy object."));
		return;
	}

	// Make Critic Instance
	ULearningAgentsPolicy* PolicyPtr = Policy;
	Critic = ULearningAgentsCritic::MakeCritic(
		ManagerPtr, InteractorPtr, PolicyPtr, ULearningAgentsCritic::StaticClass(), TEXT("FPSCharacter Critic"), 
		CriticNeuralNetwork, ReInitialize, CriticSettings, RandomSeed);
	if (Critic == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Failed to make critic object."));
		return;
	}

	// Make Training Environment Instance
	TrainingEnvironment = Cast<UFPSCharacterTrainingEnvironment>(ULearningAgentsTrainingEnvironment::MakeTrainingEnvironment(
		ManagerPtr, UFPSCharacterTrainingEnvironment::StaticClass(), TEXT("FPSCharacter Training Environment")));
	if (TrainingEnvironment == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Failed to make training environment object."));
		return;
	}
	TrainingEnvironment->TargetActor = TargetActor;
	TrainingEnvironmentBase = TrainingEnvironment;

	// Create a shared memory communicator to spawn a training process (following car example)
	FLearningAgentsCommunicator Communicator = ULearningAgentsCommunicatorLibrary::MakeSharedMemoryTrainingProcess(
		TrainerProcessSettings, SharedMemorySettings
	);

	// Make PPO Trainer Instance
	PPOTrainer = ULearningAgentsPPOTrainer::MakePPOTrainer(
		ManagerPtr, InteractorPtr, TrainingEnvironmentBase, Policy, Critic,
		Communicator, ULearningAgentsPPOTrainer::StaticClass(), TEXT("FPSCharacter PPO Trainer"), TrainerSettings);
	if (PPOTrainer == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Failed to make PPO trainer object."));
		return;
	}

	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Initialization complete. Mode: %d"), (int32)RunMode);
}

void AFPSCharacterManager::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	// Handle different run modes like in car example
	if (RunMode == EFPSCharacterManagerMode::Inference)
	{
		if (Policy != nullptr)
		{
			Policy->RunInference();
		}
	}
	else // Training or ReInitialize mode
	{
		if (PPOTrainer != nullptr)
		{
			PPOTrainer->RunTraining(TrainingSettings, TrainingGameSettings, true, true);
		}
	}
} 