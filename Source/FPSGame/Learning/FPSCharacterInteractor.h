// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "LearningAgentsInteractor.h"
#include "FPSCharacterInteractor.generated.h"

class AFPSTargetActor;

/**
 * Interactor for FPSCharacter learning agents
 */
UCLASS()
class FPSGAME_API UFPSCharacterInteractor : public ULearningAgentsInteractor
{
	GENERATED_BODY()

public:
	UFPSCharacterInteractor();

	virtual void SpecifyAgentObservation_Implementation(
		FLearningAgentsObservationSchemaElement& OutObservationSchemaElement,
		ULearningAgentsObservationSchema* InObservationSchema) override;

	virtual void GatherAgentObservation_Implementation(
		FLearningAgentsObservationObjectElement& OutObservationObjectElement,
		ULearningAgentsObservationObject* InObservationObject,
		const int32 AgentId) override;
	
	virtual void SpecifyAgentAction_Implementation(
		FLearningAgentsActionSchemaElement& OutActionSchemaElement,
		ULearningAgentsActionSchema* InActionSchema) override;

	virtual void PerformAgentAction_Implementation(
		const ULearningAgentsActionObject* InActionObject,
		const FLearningAgentsActionObjectElement& InActionObjectElement,
		const int32 AgentId) override;

	// Reference to the target actor
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Learning")
	AFPSTargetActor* TargetActor;

	// Observation settings
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Observations")
	float MaxObservationDistance = 10000.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Observations")
	float MaxVelocity = 1000.0f;
}; 