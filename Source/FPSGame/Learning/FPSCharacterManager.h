// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "LearningAgentsPolicy.h"
#include "LearningAgentsCritic.h"
#include "LearningAgentsTrainer.h"
#include "LearningAgentsPPOTrainer.h"
#include "LearningAgentsManager.h"
#include "LearningAgentsCommunicator.h"
#include "FPSCharacterManager.generated.h"

class UFPSCharacterManagerComponent;
class UFPSCharacterInteractor;
class UFPSCharacterTrainingEnvironment;
class AFPSTargetActor;
class ULearningAgentsNeuralNetwork;

UENUM(BlueprintType)
enum class EFPSCharacterManagerMode : uint8
{
	Training		UMETA(DisplayName = "Training"),
	Inference		UMETA(DisplayName = "Inference"),
	ReInitialize	UMETA(DisplayName = "ReInitialize")
};

/**
 * Main manager for FPSCharacter learning agents
 */
UCLASS()
class FPSGAME_API AFPSCharacterManager : public AActor
{
	GENERATED_BODY()
	
public:	
	AFPSCharacterManager();

protected:
	virtual void BeginPlay() override;

	// Core learning components
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Components")
	UFPSCharacterManagerComponent* LearningAgentsManager;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	ULearningAgentsInteractor* LearningAgentsInteractorBase;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	UFPSCharacterInteractor* Interactor;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	ULearningAgentsPolicy* Policy;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	ULearningAgentsCritic* Critic;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	ULearningAgentsTrainingEnvironment* TrainingEnvironmentBase;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	UFPSCharacterTrainingEnvironment* TrainingEnvironment;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	ULearningAgentsPPOTrainer* PPOTrainer;

	// Internal initialization functions
	void InitializeAgents();
	void InitializeManager();

public:	
	virtual void Tick(float DeltaTime) override;

	// Manager settings
	UPROPERTY(EditAnywhere, Category = "Manager Settings")
	EFPSCharacterManagerMode RunMode = EFPSCharacterManagerMode::Training;

	UPROPERTY(EditAnywhere, Category = "Manager Settings")
	int32 RandomSeed = 1234;

	// Learning settings
	UPROPERTY(EditAnywhere, Category = "Learning Settings")
	FLearningAgentsPolicySettings PolicySettings;

	UPROPERTY(EditAnywhere, Category = "Learning Settings")
	FLearningAgentsCriticSettings CriticSettings;

	UPROPERTY(EditAnywhere, Category = "Learning Settings")
	FLearningAgentsPPOTrainingSettings TrainingSettings;

	UPROPERTY(EditAnywhere, Category = "Learning Settings")
	FLearningAgentsTrainingGameSettings TrainingGameSettings;

	// Neural network references
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Neural Networks")
	ULearningAgentsNeuralNetwork* EncoderNeuralNetwork;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Neural Networks")
	ULearningAgentsNeuralNetwork* PolicyNeuralNetwork;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Neural Networks")
	ULearningAgentsNeuralNetwork* DecoderNeuralNetwork;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Neural Networks")
	ULearningAgentsNeuralNetwork* CriticNeuralNetwork;

	// Target actor reference
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Environment")
	AFPSTargetActor* TargetActor;

	// Trainer settings - expose these to editor like in car example
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	FLearningAgentsTrainerProcessSettings TrainerProcessSettings;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	FLearningAgentsSharedMemoryCommunicatorSettings SharedMemorySettings;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Learning Objects")
	FLearningAgentsPPOTrainerSettings TrainerSettings;
}; 