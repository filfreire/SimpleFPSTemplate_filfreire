// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "LearningAgentsTrainingEnvironment.h"
#include "FPSCharacterTrainingEnvironment.generated.h"

class AFPSTargetActor;

/**
 * Training environment for FPSCharacter learning to move to target
 */
UCLASS()
class FPSGAME_API UFPSCharacterTrainingEnvironment : public ULearningAgentsTrainingEnvironment
{
	GENERATED_BODY()

public:
	UFPSCharacterTrainingEnvironment();

	virtual void GatherAgentReward_Implementation(float& OutReward, const int32 AgentId) override;
	virtual void GatherAgentCompletion_Implementation(ELearningAgentsCompletion& OutCompletion, const int32 AgentId) override;
	virtual void ResetAgentEpisode_Implementation(const int32 AgentId) override;

	// Target actor reference
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Learning")
	AFPSTargetActor* TargetActor;

	// Reward settings
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Rewards")
	float ReachTargetReward = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Rewards")
	float DistanceRewardScale = 0.1f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Rewards")
	float MovementTowardsTargetReward = 0.5f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Rewards")
	float FacingTargetReward = 0.2f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Rewards")
	float TimeStepPenalty = -0.01f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Rewards")
	float MaxEpisodeLength = 1000.0f;

	// Reset bounds for character and target
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Environment")
	FVector ResetCenter = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Environment")
	FVector ResetBounds = FVector(2000.0f, 2000.0f, 0.0f);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Environment")
	float MinDistanceBetweenCharacterAndTarget = 500.0f;

private:
	// Store previous distances for reward calculation
	TMap<int32, float> PreviousDistances;
	TMap<int32, int32> EpisodeSteps;
}; 