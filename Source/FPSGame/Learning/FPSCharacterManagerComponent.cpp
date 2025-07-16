// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "FPSCharacterManagerComponent.h"

UFPSCharacterManagerComponent::UFPSCharacterManagerComponent()
{
	PrimaryComponentTick.bCanEverTick = false;
}

void UFPSCharacterManagerComponent::PostInitProperties()
{
	MaxAgentNum = 32; // Set maximum number of agents this manager can handle
	Super::PostInitProperties();
} 