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

void UFPSObstacleManager::InitializeObstaclesWithSmartPlacement(const FVector& AgentLocation, const FVector& TargetLocation)
{
	// Clear existing obstacles
	ClearObstacles();

	// Calculate path between agent and target
	FVector PathDirection = (TargetLocation - AgentLocation).GetSafeNormal();
	FVector PathCenter = (AgentLocation + TargetLocation) * 0.5f;
	float PathLength = FVector::Dist(AgentLocation, TargetLocation);

	// Generate obstacles with smart placement
	for (int32 i = 0; i < MaxObstacles; i++)
	{
		FVector ObstaclePosition;
		
		// 60% chance to place along the path, 40% chance random
		if (FMath::RandRange(0.0f, 1.0f) < 0.6f && PathLength > 100.0f)
		{
			// Place along the path between agent and target
			float PathProgress = FMath::RandRange(0.2f, 0.8f); // Don't place too close to start/end
			FVector PathPosition = AgentLocation + PathDirection * (PathLength * PathProgress);
			
			// Add some perpendicular offset
			FVector Perpendicular = FVector(-PathDirection.Y, PathDirection.X, 0.0f);
			float Offset = FMath::RandRange(-PathLength * 0.3f, PathLength * 0.3f);
			ObstaclePosition = PathPosition + Perpendicular * Offset;
		}
		else
		{
			// Use regular random positioning
			ObstaclePosition = GenerateRandomObstaclePosition(FVector::ZeroVector, 0.0f);
		}
		
		// Find ground level
		ObstaclePosition.Z = FindGroundLevel(ObstaclePosition);
		
		// Create obstacle if position is valid
		if (IsValidObstaclePosition(ObstaclePosition, AgentLocation, 100.0f) && 
			IsValidObstaclePosition(ObstaclePosition, TargetLocation, 100.0f))
		{
			AFPSObstacleActor* NewObstacle = CreateObstacleAtPosition(ObstaclePosition);
			if (NewObstacle)
			{
				CurrentObstacles.Add(NewObstacle);
			}
		}
	}

	UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Initialized %d obstacles with smart placement"), CurrentObstacles.Num());
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
		// Smart positioning: 70% chance to place near center (agent/target area), 30% chance random
		if (FMath::RandRange(0.0f, 1.0f) < 0.7f)
		{
			// Place obstacles closer to center where agents and targets are
			float CenterRadius = FMath::Min(EnvironmentBounds.X, EnvironmentBounds.Y) * 0.4f; // 40% of environment size
			float Angle = FMath::RandRange(0.0f, 2.0f * PI);
			float Distance = FMath::RandRange(0.0f, CenterRadius);
			
			Position.X = EnvironmentCenter.X + FMath::Cos(Angle) * Distance;
			Position.Y = EnvironmentCenter.Y + FMath::Sin(Angle) * Distance;
		}
		else
		{
			// Random placement in full environment
			Position.X = EnvironmentCenter.X + FMath::RandRange(-EnvironmentBounds.X, EnvironmentBounds.X);
			Position.Y = EnvironmentCenter.Y + FMath::RandRange(-EnvironmentBounds.Y, EnvironmentBounds.Y);
		}
		
		// Find ground level using line trace
		Position.Z = FindGroundLevel(Position);
		
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
		// Set more appropriate size - smaller and more agent-relative
		float Size = FMath::RandRange(MinObstacleSize, MaxObstacleSize);
		float Height = FMath::RandRange(Size * 0.8f, Size * 1.2f); // Height closer to width/depth
		NewObstacle->InitializeObstacle(Size, Height, Size);
		
		UE_LOG(LogTemp, VeryVerbose, TEXT("FPSObstacleManager: Created obstacle at %s with size %f (H:%f)"), 
			*Position.ToString(), Size, Height);
	}

	return NewObstacle;
}

float UFPSObstacleManager::FindGroundLevel(const FVector& Position) const
{
	if (!GetWorld())
	{
		return EnvironmentCenter.Z;
	}

	// Line trace from above to find ground
	FVector TraceStart = FVector(Position.X, Position.Y, EnvironmentCenter.Z + 1000.0f);
	FVector TraceEnd = FVector(Position.X, Position.Y, EnvironmentCenter.Z - 1000.0f);
	
	FHitResult HitResult;
	FCollisionQueryParams QueryParams;
	QueryParams.bTraceComplex = false;
	
	float GroundZ = EnvironmentCenter.Z; // Default to environment center if no ground found
	if (GetWorld()->LineTraceSingleByChannel(HitResult, TraceStart, TraceEnd, ECC_WorldStatic, QueryParams))
	{
		GroundZ = HitResult.Location.Z;
	}
	
	return GroundZ;
}

