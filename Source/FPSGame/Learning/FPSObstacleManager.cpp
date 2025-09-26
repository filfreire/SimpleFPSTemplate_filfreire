// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "Learning/FPSObstacleManager.h"
#include "Engine/World.h"
#include "Engine/Engine.h"

UFPSObstacleManager::UFPSObstacleManager()
{
	PrimaryComponentTick.bCanEverTick = false;
}

void UFPSObstacleManager::BeginPlay()
{
	Super::BeginPlay();
	
	// Initialize obstacles based on mode
	if (ObstacleMode == EObstacleMode::Static)
	{
		InitializeObstacles();
	}
}

void UFPSObstacleManager::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
}

void UFPSObstacleManager::InitializeObstacles()
{
	// Clear existing obstacles
	ClearObstacles();

	// Generate obstacles
	for (int32 i = 0; i < MaxObstacles; i++)
	{
		FVector ObstaclePosition = GenerateRandomObstaclePosition(FVector::ZeroVector, 0.0f);
		AFPSObstacleActor* NewObstacle = CreateObstacleAtPosition(ObstaclePosition);
		if (NewObstacle)
		{
			CurrentObstacles.Add(NewObstacle);
		}
	}

	UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Initialized %d obstacles in %s mode"), 
		CurrentObstacles.Num(), 
		ObstacleMode == EObstacleMode::Static ? TEXT("Static") : TEXT("Dynamic"));
}

void UFPSObstacleManager::ClearObstacles()
{
	for (AFPSObstacleActor* Obstacle : CurrentObstacles)
	{
		if (IsValid(Obstacle))
		{
			Obstacle->Destroy();
		}
	}
	CurrentObstacles.Empty();
}

void UFPSObstacleManager::RegenerateObstacles()
{
	if (ObstacleMode == EObstacleMode::Dynamic)
	{
		ClearObstacles();
		InitializeObstacles();
		UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Regenerated obstacles in dynamic mode"));
	}
}

bool UFPSObstacleManager::IsLocationBlocked(const FVector& Location, float AgentRadius) const
{
	for (AFPSObstacleActor* Obstacle : CurrentObstacles)
	{
		if (IsValid(Obstacle) && Obstacle->IsLocationBlocked(Location, AgentRadius))
		{
			return true;
		}
	}
	return false;
}

void UFPSObstacleManager::SetObstacleMode(EObstacleMode NewMode)
{
	ObstacleMode = NewMode;
	
	// If switching to static mode, initialize obstacles
	if (ObstacleMode == EObstacleMode::Static)
	{
		InitializeObstacles();
	}
	// If switching to dynamic mode, clear obstacles (they'll be generated on demand)
	else if (ObstacleMode == EObstacleMode::Dynamic)
	{
		ClearObstacles();
	}
}

FVector UFPSObstacleManager::GenerateRandomObstaclePosition(const FVector& AvoidLocation, float AvoidRadius) const
{
	FVector Position;
	int32 Attempts = 0;
	const int32 MaxAttempts = 100;

	do
	{
		Position.X = EnvironmentCenter.X + FMath::RandRange(-EnvironmentBounds.X, EnvironmentBounds.X);
		Position.Y = EnvironmentCenter.Y + FMath::RandRange(-EnvironmentBounds.Y, EnvironmentBounds.Y);
		Position.Z = EnvironmentCenter.Z; // Place on ground level
		
		Attempts++;
	} while (!IsValidObstaclePosition(Position, AvoidLocation, AvoidRadius) && Attempts < MaxAttempts);

	return Position;
}

bool UFPSObstacleManager::IsValidObstaclePosition(const FVector& Position, const FVector& AvoidLocation, float AvoidRadius) const
{
	// Check if position is within environment bounds
	if (Position.X < EnvironmentCenter.X - EnvironmentBounds.X || Position.X > EnvironmentCenter.X + EnvironmentBounds.X ||
		Position.Y < EnvironmentCenter.Y - EnvironmentBounds.Y || Position.Y > EnvironmentCenter.Y + EnvironmentBounds.Y)
	{
		return false;
	}

	// Check distance from avoid location
	if (AvoidRadius > 0.0f && FVector::Dist(Position, AvoidLocation) < AvoidRadius)
	{
		return false;
	}

	// Check distance from existing obstacles
	for (AFPSObstacleActor* Obstacle : CurrentObstacles)
	{
		if (IsValid(Obstacle))
		{
			float Distance = FVector::Dist(Position, Obstacle->GetActorLocation());
			if (Distance < MinObstacleSize) // Minimum distance between obstacles
			{
				return false;
			}
		}
	}

	return true;
}

AFPSObstacleActor* UFPSObstacleManager::CreateObstacleAtPosition(const FVector& Position)
{
	if (!GetWorld() || !ObstacleClass)
	{
		return nullptr;
	}

	// Spawn obstacle
	FActorSpawnParameters SpawnParams;
	SpawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
	
	AFPSObstacleActor* NewObstacle = GetWorld()->SpawnActor<AFPSObstacleActor>(ObstacleClass, Position, FRotator::ZeroRotator, SpawnParams);
	
	if (NewObstacle)
	{
		// Set random size
		float Size = FMath::RandRange(MinObstacleSize, MaxObstacleSize);
		NewObstacle->InitializeObstacle(Size, Size * 1.5f, Size); // Height is 1.5x width/depth
		
		UE_LOG(LogTemp, VeryVerbose, TEXT("FPSObstacleManager: Created obstacle at %s with size %f"), 
			*Position.ToString(), Size);
	}

	return NewObstacle;
}

