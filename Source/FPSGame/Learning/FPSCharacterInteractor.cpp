// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "FPSCharacterInteractor.h"
#include "LearningAgentsObservations.h"
#include "LearningAgentsActions.h"
#include "LearningAgentsManager.h"
#include "FPSTargetActor.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "FPSCharacter.h"

UFPSCharacterInteractor::UFPSCharacterInteractor()
{
	TargetActor = nullptr;
}

void UFPSCharacterInteractor::SpecifyAgentObservation_Implementation(
	FLearningAgentsObservationSchemaElement& OutObservationSchemaElement,
	ULearningAgentsObservationSchema* InObservationSchema)
{
	// Define observations for the character learning task
	TMap<FName, FLearningAgentsObservationSchemaElement> CharacterObservations;

	// Character position relative to world
	CharacterObservations.Add("CharacterLocation", 
		ULearningAgentsObservations::SpecifyLocationObservation(
			InObservationSchema, MaxObservationDistance, "LocationObservation"));

	// Character velocity
	CharacterObservations.Add("CharacterVelocity", 
		ULearningAgentsObservations::SpecifyVelocityObservation(InObservationSchema, MaxVelocity));

	// Character forward direction
	CharacterObservations.Add("CharacterDirection", 
		ULearningAgentsObservations::SpecifyDirectionObservation(InObservationSchema, "DirectionObservation"));

	// Target position relative to world
	CharacterObservations.Add("TargetLocation", 
		ULearningAgentsObservations::SpecifyLocationObservation(
			InObservationSchema, MaxObservationDistance, "LocationObservation"));

	// Direction from character to target
	CharacterObservations.Add("DirectionToTarget", 
		ULearningAgentsObservations::SpecifyDirectionObservation(InObservationSchema, "DirectionObservation"));

	// Distance to target (normalized)
	CharacterObservations.Add("DistanceToTarget", 
		ULearningAgentsObservations::SpecifyFloatObservation(InObservationSchema, MaxObservationDistance));

	// Facing alignment to target (-1 to 1, where 1 means perfectly facing target)
	CharacterObservations.Add("FacingAlignment", 
		ULearningAgentsObservations::SpecifyFloatObservation(InObservationSchema, 1.0f));

	// Set the complete observation schema
	OutObservationSchemaElement = ULearningAgentsObservations::SpecifyStructObservation(InObservationSchema, CharacterObservations);
}

void UFPSCharacterInteractor::GatherAgentObservation_Implementation(
	FLearningAgentsObservationObjectElement& OutObservationObjectElement,
	ULearningAgentsObservationObject* InObservationObject, const int32 AgentId)
{
	// Get the character agent
	const AFPSCharacter* Character = Cast<AFPSCharacter>(Manager->GetAgent(AgentId, AFPSCharacter::StaticClass()));
	
	if (!Character || !TargetActor)
	{
		if (!Character)
		{
			UE_LOG(LogTemp, Error, TEXT("FPSCharacterInteractor: Failed to get character for agent %d"), AgentId);
		}
		if (!TargetActor)
		{
			UE_LOG(LogTemp, Error, TEXT("FPSCharacterInteractor: TargetActor is NULL - make sure FPSCharacterManager.TargetActor is set!"));
		}
		return;
	}

	// Gather character observations
	TMap<FName, FLearningAgentsObservationObjectElement> CharacterObservationObject;

	// Character location
	CharacterObservationObject.Add("CharacterLocation", 
		ULearningAgentsObservations::MakeLocationObservation(InObservationObject, Character->GetActorLocation()));

	// Character velocity
	FVector CharacterVelocity = FVector::ZeroVector;
	if (const UCharacterMovementComponent* MovementComp = Character->GetCharacterMovement())
	{
		CharacterVelocity = MovementComp->Velocity;
	}
	CharacterObservationObject.Add("CharacterVelocity", 
		ULearningAgentsObservations::MakeVelocityObservation(InObservationObject, CharacterVelocity));

	// Character forward direction
	CharacterObservationObject.Add("CharacterDirection", 
		ULearningAgentsObservations::MakeDirectionObservation(InObservationObject, Character->GetActorForwardVector()));

	// Target location
	CharacterObservationObject.Add("TargetLocation", 
		ULearningAgentsObservations::MakeLocationObservation(InObservationObject, TargetActor->GetActorLocation()));

	// Direction from character to target
	FVector DirectionToTarget = (TargetActor->GetActorLocation() - Character->GetActorLocation()).GetSafeNormal();
	CharacterObservationObject.Add("DirectionToTarget", 
		ULearningAgentsObservations::MakeDirectionObservation(InObservationObject, DirectionToTarget));

	// Distance to target
	float DistanceToTarget = FVector::Dist(Character->GetActorLocation(), TargetActor->GetActorLocation());
	CharacterObservationObject.Add("DistanceToTarget", 
		ULearningAgentsObservations::MakeFloatObservation(InObservationObject, DistanceToTarget));

	// Facing angle to target (how well aligned the character is with the target)
	FVector CharacterForward = Character->GetActorForwardVector();
	float FacingAlignment = FVector::DotProduct(CharacterForward, DirectionToTarget);
	CharacterObservationObject.Add("FacingAlignment", 
		ULearningAgentsObservations::MakeFloatObservation(InObservationObject, FacingAlignment));

	// Set the complete observation object
	OutObservationObjectElement = ULearningAgentsObservations::MakeStructObservation(InObservationObject, CharacterObservationObject);
}

void UFPSCharacterInteractor::SpecifyAgentAction_Implementation(
	FLearningAgentsActionSchemaElement& OutActionSchemaElement,
	ULearningAgentsActionSchema* InActionSchema)
{
	// Define actions for character movement
	TMap<FName, FLearningAgentsActionSchemaElement> CharacterActions;

	// Movement input (forward/backward)
	CharacterActions.Add("MoveForward", 
		ULearningAgentsActions::SpecifyFloatAction(InActionSchema, 1.0f, "FloatAction"));

	// Movement input (left/right)
	CharacterActions.Add("MoveRight", 
		ULearningAgentsActions::SpecifyFloatAction(InActionSchema, 1.0f, "FloatAction"));

	// Rotation input (yaw)
	CharacterActions.Add("Turn", 
		ULearningAgentsActions::SpecifyFloatAction(InActionSchema, 1.0f, "FloatAction"));

	// Look up/down input (pitch)
	CharacterActions.Add("LookUp", 
		ULearningAgentsActions::SpecifyFloatAction(InActionSchema, 1.0f, "FloatAction"));

	// Set the complete action schema
	OutActionSchemaElement = ULearningAgentsActions::SpecifyStructAction(InActionSchema, CharacterActions);
}

void UFPSCharacterInteractor::PerformAgentAction_Implementation(
	const ULearningAgentsActionObject* InActionObject,
	const FLearningAgentsActionObjectElement& InActionObjectElement,
	const int32 AgentId)
{
	// Get the character agent
	AFPSCharacter* Character = Cast<AFPSCharacter>(Manager->GetAgent(AgentId, AFPSCharacter::StaticClass()));
	
	if (!Character)
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterInteractor: Failed to get character for agent %d in PerformAgentAction"), AgentId);
		return;
	}

	// Extract actions from the action object
	TMap<FName, FLearningAgentsActionObjectElement> CharacterActionObjects;
	if (!ULearningAgentsActions::GetStructAction(CharacterActionObjects, InActionObject, InActionObjectElement))
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterInteractor: Failed to get struct action for agent %d"), AgentId);
		return;
	}

	// Get movement actions
	float MoveForwardValue = 0.0f;
	float MoveRightValue = 0.0f;
	float TurnValue = 0.0f;
	float LookUpValue = 0.0f;

	const FLearningAgentsActionObjectElement* MoveForwardAction = CharacterActionObjects.Find("MoveForward");
	if (MoveForwardAction && !ULearningAgentsActions::GetFloatAction(MoveForwardValue, InActionObject, *MoveForwardAction))
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterInteractor: Failed to get MoveForward action for agent %d"), AgentId);
	}

	const FLearningAgentsActionObjectElement* MoveRightAction = CharacterActionObjects.Find("MoveRight");
	if (MoveRightAction && !ULearningAgentsActions::GetFloatAction(MoveRightValue, InActionObject, *MoveRightAction))
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterInteractor: Failed to get MoveRight action for agent %d"), AgentId);
	}

	const FLearningAgentsActionObjectElement* TurnAction = CharacterActionObjects.Find("Turn");
	if (TurnAction && !ULearningAgentsActions::GetFloatAction(TurnValue, InActionObject, *TurnAction))
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterInteractor: Failed to get Turn action for agent %d"), AgentId);
	}

	const FLearningAgentsActionObjectElement* LookUpAction = CharacterActionObjects.Find("LookUp");
	if (LookUpAction && !ULearningAgentsActions::GetFloatAction(LookUpValue, InActionObject, *LookUpAction))
	{
		UE_LOG(LogTemp, Error, TEXT("FPSCharacterInteractor: Failed to get LookUp action for agent %d"), AgentId);
	}

	// DEBUG: Log action values for each agent
	static int32 LogCounter = 0;
	LogCounter++;
	if (LogCounter % 60 == 0) // Log every 60 calls (roughly every second at 60fps)
	{
		UE_LOG(LogTemp, Warning, TEXT("AGENT %d ACTION: Forward=%.3f, Right=%.3f, Turn=%.3f, LookUp=%.3f"), 
			AgentId, MoveForwardValue, MoveRightValue, TurnValue, LookUpValue);
	}

	// Apply movement actions to the character
	if (Character)
	{
		// Apply forward/backward movement using AddMovementInput
		if (FMath::Abs(MoveForwardValue) > 0.01f)
		{
			Character->AddMovementInput(Character->GetActorForwardVector(), MoveForwardValue);
		}
		
		// Apply left/right movement using AddMovementInput
		if (FMath::Abs(MoveRightValue) > 0.01f)
		{
			Character->AddMovementInput(Character->GetActorRightVector(), MoveRightValue);
		}
		
		// Apply rotation (yaw) with increased sensitivity for better target facing
		if (FMath::Abs(TurnValue) > 0.01f)
		{
			float TurnScale = 2.0f; // Increase rotation sensitivity
			Character->AddControllerYawInput(TurnValue * TurnScale);
		}

		// Apply pitch rotation for looking up/down
		if (FMath::Abs(LookUpValue) > 0.01f)
		{
			float LookUpScale = 1.0f;
			Character->AddControllerPitchInput(LookUpValue * LookUpScale);
		}
	}
} 