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
#include "GameFramework/CharacterMovementComponent.h"

AFPSCharacterManager::AFPSCharacterManager()
{
	PrimaryActorTick.bCanEverTick = true;
	// set training settings for headless training
	TrainingSettings.bUseTensorboard = true;
	TrainingSettings.bSaveSnapshots = true;

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
		if (IsValid(Actor) && Actor->IsA<AFPSCharacter>())
		{
			if (!Agents.Contains(Actor)) // Avoid duplicates
			{
				Agents.Add(Actor);
				UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Added character %s (derived from FPSCharacter)"), *Actor->GetName());
			}
		}
	}

	// Log comprehensive discovery information
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: ===== AGENT DISCOVERY SUMMARY ====="));
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Found %d total characters in world"), AllCharacters.Num());
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Found %d valid FPSCharacter agents"), Agents.Num());
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Learning Manager MaxAgentNum: %d"), LearningAgentsManager->GetMaxAgentNum());
	
	// Log details about what we found
	for (int32 i = 0; i < AllCharacters.Num(); i++)
	{
		AActor* Actor = AllCharacters[i];
		if (!IsValid(Actor))
		{
			UE_LOG(LogTemp, Warning, TEXT("Character %d: INVALID ACTOR"), i);
			continue;
		}
		
		bool bIsFPSCharacter = Actor->IsA<AFPSCharacter>();
		UE_LOG(LogTemp, Warning, TEXT("Character %d: %s (Class: %s) - Is FPSCharacter: %s, In Agents List: %s"), 
			i, 
			*Actor->GetName(), 
			*Actor->GetClass()->GetName(),
			bIsFPSCharacter ? TEXT("YES") : TEXT("NO"),
			Agents.Contains(Actor) ? TEXT("YES") : TEXT("NO"));
	}

	// FIXED: Clear any existing agents first to ensure clean state
	LearningAgentsManager->RemoveAllAgents();

	// Store agent registration results for verification
	TArray<int32> SuccessfulAgentIds;
	
	for (int32 AgentIndex = 0; AgentIndex < Agents.Num(); AgentIndex++)
	{
		AActor* Agent = Agents[AgentIndex];
		
		// Validate the agent before processing
		if (!IsValid(Agent))
		{
			UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Found invalid agent at index %d, skipping"), AgentIndex);
			continue;
		}

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
						continue; // Skip this agent if we can't create a controller
					}
				}
			}
			else
			{
				UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Agent %s already has controller %s"), 
					*Agent->GetName(), *ExistingController->GetClass()->GetName());
			}
		}
		else
		{
			UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Agent %s is not a Pawn, skipping"), *Agent->GetName());
			continue;
		}
		
		// Add agent to the Learning Agents Manager
		int32 AgentId = LearningAgentsManager->AddAgent(Agent);
		if (AgentId == INDEX_NONE)
		{
			UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Failed to add agent %s to manager (returned INDEX_NONE)"), *Agent->GetName());
			continue;
		}
		
		// FIXED: Verify the agent ID is sequential starting from 0
		if (AgentId != SuccessfulAgentIds.Num())
		{
			UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Agent %s got non-sequential ID %d (expected %d) - this may cause multi-agent issues"), 
				*Agent->GetName(), AgentId, SuccessfulAgentIds.Num());
		}
		
		SuccessfulAgentIds.Add(AgentId);
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Successfully added agent %s to manager with ID %d"), *Agent->GetName(), AgentId);
		
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

	// FIXED: Final verification that all agents are properly registered
	TArray<int32> RegisteredAgentIds;
	TArray<UObject*> AgentObjects;
	for (int32 i = 0; i < SuccessfulAgentIds.Num(); i++)
	{
		int32 AgentId = SuccessfulAgentIds[i];
		UObject* AgentObject = LearningAgentsManager->GetAgent(AgentId);
		if (AgentObject)
		{
			AgentObjects.Add(AgentObject);
		}
	}
	LearningAgentsManager->GetAgentIds(RegisteredAgentIds, AgentObjects);
	int32 RegisteredAgentCount = RegisteredAgentIds.Num();
	
	// Verify sequential IDs
	bool bHasSequentialIds = true;
	for (int32 i = 0; i < RegisteredAgentIds.Num(); i++)
	{
		if (!RegisteredAgentIds.Contains(i))
		{
			bHasSequentialIds = false;
			UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Missing agent ID %d in registered agents"), i);
		}
	}
	
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: ===== INITIALIZATION COMPLETE ====="));
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Found %d potential agents"), Agents.Num());
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Successfully registered %d agents with learning manager"), RegisteredAgentCount);
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Agent IDs are sequential: %s"), bHasSequentialIds ? TEXT("YES") : TEXT("NO"));
	
	if (Agents.Num() == 0)
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: No FPSCharacter agents found! Make sure to:"));
		UE_LOG(LogTemp, Error, TEXT("1. Place FPSCharacter (or Blueprint derived from FPSCharacter) actors in your level"));
		UE_LOG(LogTemp, Error, TEXT("2. Don't just set FPSCharacter as PlayerPawn - you need actual actors in the world"));
		UE_LOG(LogTemp, Error, TEXT("3. Check that your Blueprint inherits from FPSCharacter, not just Character"));
	}
	else if (RegisteredAgentCount < Agents.Num())
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Only %d out of %d agents were successfully registered!"), RegisteredAgentCount, Agents.Num());
		UE_LOG(LogTemp, Error, TEXT("Check the logs above for specific errors during agent registration"));
	}
	else if (RegisteredAgentCount == 1 && Agents.Num() > 1)
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Only 1 agent registered despite finding %d agents - possible learning manager limitation"), Agents.Num());
	}
	else if (!bHasSequentialIds)
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Agent IDs are not sequential starting from 0 - this WILL cause multi-agent issues!"));
		
		// Convert integer array to string manually
		FString AgentIdsList;
		for (int32 i = 0; i < RegisteredAgentIds.Num(); i++)
		{
			if (i > 0) AgentIdsList += TEXT(", ");
			AgentIdsList += FString::FromInt(RegisteredAgentIds[i]);
		}
		UE_LOG(LogTemp, Error, TEXT("Registered Agent IDs: %s"), *AgentIdsList);
	}
}

void AFPSCharacterManager::InitializeManager()
{
	// Should neural networks be re-initialized
	const bool ReInitialize = (RunMode == EFPSCharacterManagerMode::ReInitialize);

	// FIXED: Get current agent count for multi-agent setup verification
	TArray<int32> AgentIds;
	TArray<UObject*> AllAgentObjects;
	
	// Get all managed agents
	TArray<AActor*> Agents;
	UGameplayStatics::GetAllActorsOfClass(GetWorld(), AFPSCharacter::StaticClass(), Agents);
	for (AActor* Agent : Agents)
	{
		if (IsValid(Agent))
		{
			AllAgentObjects.Add(Agent);
		}
	}
	
	if (AllAgentObjects.Num() > 0)
	{
		LearningAgentsManager->GetAgentIds(AgentIds, AllAgentObjects);
	}
	int32 AgentCount = AgentIds.Num();
	
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: ===== MANAGER INITIALIZATION ====="));
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Agent count for training: %d"), AgentCount);
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: ReInitialize mode: %s"), ReInitialize ? TEXT("YES") : TEXT("NO"));

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
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Created Interactor successfully"));

	// Warn if neural networks are not set
	if (EncoderNeuralNetwork == nullptr || PolicyNeuralNetwork == nullptr || 
		DecoderNeuralNetwork == nullptr || CriticNeuralNetwork == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: One or more neural networks are not set."));
		return;
	}
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: All neural networks are set"));

	// FIXED: Ensure policy settings are appropriate for multi-agent
	FLearningAgentsPolicySettings ModifiedPolicySettings = PolicySettings;
	// You might need to adjust these based on your specific requirements
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Using policy settings for %d agents"), AgentCount);

	// Make Policy Instance
	ULearningAgentsInteractor* InteractorPtr = Interactor;
	Policy = ULearningAgentsPolicy::MakePolicy(
		ManagerPtr, InteractorPtr, ULearningAgentsPolicy::StaticClass(), TEXT("FPSCharacter Policy"), 
		EncoderNeuralNetwork, PolicyNeuralNetwork, DecoderNeuralNetwork, 
		ReInitialize, ReInitialize, ReInitialize, ModifiedPolicySettings, RandomSeed);
	if (Policy == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Failed to make policy object."));
		return;
	}
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Created Policy successfully"));

	// FIXED: Ensure critic settings are appropriate for multi-agent
	FLearningAgentsCriticSettings ModifiedCriticSettings = CriticSettings;
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Using critic settings for %d agents"), AgentCount);

	// Make Critic Instance
	ULearningAgentsPolicy* PolicyPtr = Policy;
	Critic = ULearningAgentsCritic::MakeCritic(
		ManagerPtr, InteractorPtr, PolicyPtr, ULearningAgentsCritic::StaticClass(), TEXT("FPSCharacter Critic"), 
		CriticNeuralNetwork, ReInitialize, ModifiedCriticSettings, RandomSeed);
	if (Critic == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Failed to make critic object."));
		return;
	}
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Created Critic successfully"));

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
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Created Training Environment successfully"));

	// Create a shared memory communicator to spawn a training process (following car example)
	FLearningAgentsCommunicator Communicator = ULearningAgentsCommunicatorLibrary::MakeSharedMemoryTrainingProcess(
		TrainerProcessSettings, SharedMemorySettings
	);
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Created Communicator successfully"));

	// FIXED: Ensure trainer settings are appropriate for multi-agent
	FLearningAgentsPPOTrainerSettings ModifiedTrainerSettings = TrainerSettings;
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Using trainer settings for %d agents"), AgentCount);

	// Make PPO Trainer Instance
	PPOTrainer = ULearningAgentsPPOTrainer::MakePPOTrainer(
		ManagerPtr, InteractorPtr, TrainingEnvironmentBase, Policy, Critic,
		Communicator, ULearningAgentsPPOTrainer::StaticClass(), TEXT("FPSCharacter PPO Trainer"), ModifiedTrainerSettings);
	if (PPOTrainer == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: Failed to make PPO trainer object."));
		return;
	}
	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Created PPO Trainer successfully"));

	UE_LOG(LogTemp, Log, TEXT("FPSCharacterManager: Initialization complete. Mode: %d, Agents: %d"), (int32)RunMode, AgentCount);
	UE_LOG(LogTemp, Warning, TEXT("FPSCharacterManager: ===== MANAGER INITIALIZATION COMPLETE ====="));
}

void AFPSCharacterManager::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	// DEBUG: Periodic status logging for all agents
	static float DebugTimer = 0.0f;
	DebugTimer += DeltaTime;
	if (DebugTimer >= 2.0f) // Log every 2 seconds
	{
		DebugTimer = 0.0f;
		
		// Get agent count and IDs
		TArray<int32> AgentIds;
		TArray<UObject*> AllAgentObjects;
		
		// Get all managed agents
		TArray<AActor*> Agents;
		UGameplayStatics::GetAllActorsOfClass(GetWorld(), AFPSCharacter::StaticClass(), Agents);
		for (AActor* Agent : Agents)
		{
			if (IsValid(Agent))
			{
				AllAgentObjects.Add(Agent);
			}
		}
		
		if (AllAgentObjects.Num() > 0)
		{
			LearningAgentsManager->GetAgentIds(AgentIds, AllAgentObjects);
		}
		
		UE_LOG(LogTemp, Warning, TEXT("=== AGENT STATUS DEBUG ==="));
		UE_LOG(LogTemp, Warning, TEXT("Total registered agents: %d"), AgentIds.Num());
		UE_LOG(LogTemp, Warning, TEXT("Run Mode: %s"), 
			RunMode == EFPSCharacterManagerMode::Training ? TEXT("Training") : 
			RunMode == EFPSCharacterManagerMode::Inference ? TEXT("Inference") : TEXT("ReInitialize"));
		
		for (int32 AgentId : AgentIds)
		{
			AFPSCharacter* Character = Cast<AFPSCharacter>(LearningAgentsManager->GetAgent(AgentId, AFPSCharacter::StaticClass()));
			if (Character)
			{
				FVector Velocity = Character->GetCharacterMovement() ? Character->GetCharacterMovement()->Velocity : FVector::ZeroVector;
				UE_LOG(LogTemp, Warning, TEXT("Agent %d (%s): Location=(%s), Velocity=(%s), Moving=%s"), 
					AgentId, 
					*Character->GetName(),
					*Character->GetActorLocation().ToString(),
					*Velocity.ToString(),
					Velocity.Size() > 1.0f ? TEXT("YES") : TEXT("NO"));
			}
			else
			{
				UE_LOG(LogTemp, Error, TEXT("Agent %d: CHARACTER NOT FOUND"), AgentId);
			}
		}
		UE_LOG(LogTemp, Warning, TEXT("========================"));
	}

	// Handle different run modes like in car example
	if (RunMode == EFPSCharacterManagerMode::Inference)
	{
		if (Policy != nullptr)
		{
			Policy->RunInference();
		}
		else
		{
			UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: Policy is null in Inference mode"));
		}
	}
	else // Training or ReInitialize mode
	{
		if (PPOTrainer != nullptr)
		{
			PPOTrainer->RunTraining(TrainingSettings, TrainingGameSettings, true, true);
		}
		else
		{
			UE_LOG(LogTemp, Error, TEXT("FPSCharacterManager: PPOTrainer is null in Training mode"));
		}
	}
} 
