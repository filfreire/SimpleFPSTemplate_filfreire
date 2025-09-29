// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "FPSCharacterManagerComponent.generated.h"
#include "LearningAgentsManager.h"

/**
 * Manager component for FPSCharacter learning agents
 */
UCLASS(BlueprintType, Blueprintable, ClassGroup = (LearningAgents), meta = (BlueprintSpawnableComponent))
class FPSGAME_API UFPSCharacterManagerComponent : public ULearningAgentsManager
{
	GENERATED_BODY()

  public:
	UFPSCharacterManagerComponent();

  protected:
	virtual void PostInitProperties() override;
};
