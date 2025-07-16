// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "FPSCharacterTrainingEnvironment.h"
#include "LearningAgentsManager.h"
#include "LearningAgentsCompletions.h"
#include "FPSTargetActor.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "FPSCharacter.h"

UFPSCharacterTrainingEnvironment::UFPSCharacterTrainingEnvironment()
{
	TargetActor = nullptr;
}

void UFPSCharacterTrainingEnvironment::GatherAgentReward_Implementation(float& OutReward, const int32 AgentId)
{
	OutReward = 0.0f;

	// Get the character agent
	AFPSCharacter* Character = Cast<AFPSCharacter>(Manager->GetAgent(AgentId, AFPSCharacter::StaticClass()));
	if (!Character || !TargetActor)
	{
		return;
	}

	FVector CharacterLocation = Character->GetActorLocation();
	FVector TargetLocation = TargetActor->GetActorLocation();
	float CurrentDistance = FVector::Dist(CharacterLocation, TargetLocation);

	// Check if agent reached the target
	if (TargetActor->IsLocationWithinReach(CharacterLocation))
	{
		OutReward += ReachTargetReward;
		UE_LOG(LogTemp, Log, TEXT("Agent %d reached target! Reward: %f"), AgentId, ReachTargetReward);
	}
	else
	{
		// Distance-based reward (closer = better)
		float MaxDistance = FVector::Dist(ResetCenter - ResetBounds, ResetCenter + ResetBounds);
		float NormalizedDistance = FMath::Clamp(CurrentDistance / MaxDistance, 0.0f, 1.0f);
		OutReward += (1.0f - NormalizedDistance) * DistanceRewardScale;

		// Movement towards target reward
		if (PreviousDistances.Contains(AgentId))
		{
			float PreviousDistance = PreviousDistances[AgentId];
			if (CurrentDistance < PreviousDistance)
			{
				OutReward += MovementTowardsTargetReward;
			}
		}
		
		// Facing target reward - encourage agent to look at the target
		FVector DirectionToTarget = (TargetLocation - CharacterLocation).GetSafeNormal();
		FVector CharacterForward = Character->GetActorForwardVector();
		float DotProduct = FVector::DotProduct(CharacterForward, DirectionToTarget);
		
		// DotProduct ranges from -1 (opposite direction) to 1 (same direction)
		// Convert to 0-1 range and apply reward
		float FacingAlignment = (DotProduct + 1.0f) * 0.5f;
		OutReward += FacingAlignment * FacingTargetReward;
	}

	// Time step penalty to encourage efficiency
	OutReward += TimeStepPenalty;

	// Update previous distance for next step
	PreviousDistances.Add(AgentId, CurrentDistance);

	// Increment episode step counter
	if (EpisodeSteps.Contains(AgentId))
	{
		EpisodeSteps[AgentId]++;
	}
	else
	{
		EpisodeSteps.Add(AgentId, 1);
	}
}

void UFPSCharacterTrainingEnvironment::GatherAgentCompletion_Implementation(ELearningAgentsCompletion& OutCompletion, const int32 AgentId)
{
	OutCompletion = ELearningAgentsCompletion::Running;

	// Get the character agent
	AFPSCharacter* Character = Cast<AFPSCharacter>(Manager->GetAgent(AgentId, AFPSCharacter::StaticClass()));
	if (!Character || !TargetActor)
	{
		UE_LOG(LogTemp, Error, TEXT("Agent %d: Completion check failed - Character: %s, Target: %s"), 
			AgentId, Character ? TEXT("Valid") : TEXT("NULL"), TargetActor ? TEXT("Valid") : TEXT("NULL"));
		OutCompletion = ELearningAgentsCompletion::Termination;
		return;
	}

	// Check if agent reached the target
	if (TargetActor->IsLocationWithinReach(Character->GetActorLocation()))
	{
		UE_LOG(LogTemp, Log, TEXT("Agent %d (%s): Episode complete - reached target"), AgentId, *Character->GetName());
		OutCompletion = ELearningAgentsCompletion::Termination;
		return;
	}

	// Check if episode has exceeded maximum length
	int32 CurrentSteps = EpisodeSteps.FindRef(AgentId);
	if (CurrentSteps >= (int32)MaxEpisodeLength)
	{
		UE_LOG(LogTemp, Log, TEXT("Agent %d (%s): Episode complete - max steps reached (%d)"), 
			AgentId, *Character->GetName(), CurrentSteps);
		OutCompletion = ELearningAgentsCompletion::Termination;
		return;
	}

	// Check if character is outside bounds
	FVector CharacterLocation = Character->GetActorLocation();
	FVector BoundsMin = ResetCenter - ResetBounds;
	FVector BoundsMax = ResetCenter + ResetBounds;
	
	if (CharacterLocation.X < BoundsMin.X || CharacterLocation.X > BoundsMax.X ||
		CharacterLocation.Y < BoundsMin.Y || CharacterLocation.Y > BoundsMax.Y)
	{
		UE_LOG(LogTemp, Log, TEXT("Agent %d (%s): Episode complete - out of bounds"), AgentId, *Character->GetName());
		OutCompletion = ELearningAgentsCompletion::Termination;
		return;
	}
}

void UFPSCharacterTrainingEnvironment::ResetAgentEpisode_Implementation(const int32 AgentId)
{
	// Get the character agent
	AFPSCharacter* Character = Cast<AFPSCharacter>(Manager->GetAgent(AgentId, AFPSCharacter::StaticClass()));
	if (!Character || !TargetActor)
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterTrainingEnvironment: Reset failed for Agent %d - Character: %s, Target: %s"), 
			AgentId, 
			Character ? TEXT("Valid") : TEXT("NULL"), 
			TargetActor ? TEXT("Valid") : TEXT("NULL"));
		return;
	}

	// Reset episode step counter
	EpisodeSteps.Add(AgentId, 0);
	PreviousDistances.Remove(AgentId);

	// Reset character to random position with proper Z offset to avoid floor clipping
	FVector CharacterResetLocation;
	CharacterResetLocation.X = ResetCenter.X + FMath::RandRange(-ResetBounds.X, ResetBounds.X);
	CharacterResetLocation.Y = ResetCenter.Y + FMath::RandRange(-ResetBounds.Y, ResetBounds.Y);
	CharacterResetLocation.Z = ResetCenter.Z + FMath::Max(ResetBounds.Z, 100.0f); // Ensure minimum 100 units above ground

	// Reset character position and rotation
	Character->SetActorLocation(CharacterResetLocation);
	Character->SetActorRotation(FRotator(0, FMath::RandRange(0.0f, 360.0f), 0)); // Random yaw rotation

	// Reset character velocity
	if (UCharacterMovementComponent* MovementComponent = Character->GetCharacterMovement())
	{
		MovementComponent->Velocity = FVector::ZeroVector;
	}

	// Reset target to random position (ensuring minimum distance from character)
	// For multi-agent, we only move the target when the first agent resets to avoid conflicts
	if (AgentId == 0 || !TargetActor)
	{
		FVector TargetResetLocation;
		int32 Attempts = 0;
		do {
			TargetResetLocation.X = ResetCenter.X + FMath::RandRange(-ResetBounds.X, ResetBounds.X);
			TargetResetLocation.Y = ResetCenter.Y + FMath::RandRange(-ResetBounds.Y, ResetBounds.Y);
			TargetResetLocation.Z = ResetCenter.Z + FMath::Max(ResetBounds.Z, 100.0f); // Keep above ground
			Attempts++;
		} while (FVector::Dist(CharacterResetLocation, TargetResetLocation) < MinDistanceBetweenCharacterAndTarget && Attempts < 100);

		TargetActor->SetActorLocation(TargetResetLocation);
		
		UE_LOG(LogTemp, Log, TEXT("Reset Target for Agent %d - Target: %s"), AgentId, *TargetResetLocation.ToString());
	}

	UE_LOG(LogTemp, Log, TEXT("Reset Agent %d (%s) - Character: %s, Distance to Target: %f"), 
		AgentId, 
		*Character->GetName(),
		*CharacterResetLocation.ToString(),
		FVector::Dist(CharacterResetLocation, TargetActor->GetActorLocation()));
} 