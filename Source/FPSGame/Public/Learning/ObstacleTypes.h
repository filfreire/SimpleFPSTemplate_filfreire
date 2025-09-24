// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "ObstacleTypes.generated.h"

UENUM(BlueprintType)
enum class EObstacleMode : uint8
{
	Static		UMETA(DisplayName = "Static Mode"),
	Dynamic		UMETA(DisplayName = "Dynamic Mode")
};
