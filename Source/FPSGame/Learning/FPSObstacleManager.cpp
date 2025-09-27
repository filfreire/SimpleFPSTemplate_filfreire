// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "Learning/FPSObstacleManager.h"
#include "Engine/World.h"
#include "Engine/Engine.h"
#include "GameFramework/Volume.h"
#include "EngineUtils.h"

UFPSObstacleManager::UFPSObstacleManager()
{
	PrimaryComponentTick.bCanEverTick = true;
	PrimaryComponentTick.TickInterval = 1.0f; // Tick every second
}

void UFPSObstacleManager::BeginPlay()
{
	Super::BeginPlay();
	
	// Try to find location volume automatically
	FindAndSetLocationVolume();
	
	// Initialize obstacles based on mode
	if (ObstacleMode == EObstacleMode::Static)
	{
		InitializeObstacles();
	}
	else if (ObstacleMode == EObstacleMode::Dynamic)
	{
		// Initialize obstacles for dynamic mode too, they'll be shuffled by timer
		InitializeObstacles();
		ShuffleTimer = 0.0f; // Reset timer
	}
}

void UFPSObstacleManager::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	
	// Only shuffle in dynamic mode
	if (ObstacleMode == EObstacleMode::Dynamic)
	{
		ShuffleTimer += DeltaTime;
		
		// Shuffle obstacles every 60 seconds
		if (ShuffleTimer >= 60.0f)
		{
			ShuffleObstaclePositions();
			ShuffleTimer = 0.0f;
		}
	}
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

	// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Initialized %d obstacles in %s mode"), 
	//		CurrentObstacles.Num(), 
	//		ObstacleMode == EObstacleMode::Static ? TEXT("Static") : TEXT("Dynamic"));
}

void UFPSObstacleManager::InitializeObstaclesWithSmartPlacement(const FVector& AgentLocation, const FVector& TargetLocation)
{
	// Clear existing obstacles
	ClearObstacles();

	// Generate obstacles with smart placement
	for (int32 i = 0; i < MaxObstacles; i++)
	{
		FVector ObstaclePosition;
		int32 Attempts = 0;
		const int32 MaxAttempts = 50;
		bool ValidPosition = false;

		// Try to find a valid position that avoids agents and targets
		do
		{
		if (LocationVolume)
		{
			// Use LocationVolume for positioning
			FVector VolumeOrigin = LocationVolume->GetActorLocation();
			FVector VolumeExtent;
			LocationVolume->GetActorBounds(false, VolumeOrigin, VolumeExtent);
			
			// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Volume Origin: %s, Extent: %s"), 
				// *VolumeOrigin.ToString(), *VolumeExtent.ToString());
			
			// Generate random point within volume bounds
			ObstaclePosition.X = FMath::RandRange(VolumeOrigin.X - VolumeExtent.X, VolumeOrigin.X + VolumeExtent.X);
			ObstaclePosition.Y = FMath::RandRange(VolumeOrigin.Y - VolumeExtent.Y, VolumeOrigin.Y + VolumeExtent.Y);
			ObstaclePosition.Z = VolumeOrigin.Z + VolumeExtent.Z; // Start from top of volume
			
			// Find ground level
			ObstaclePosition.Z = FindGroundLevel(ObstaclePosition);
			
			// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Generated obstacle position: %s"), *ObstaclePosition.ToString());
		}
		else
			{
				// Fallback to environment bounds
				ObstaclePosition.X = EnvironmentCenter.X + FMath::RandRange(-EnvironmentBounds.X, EnvironmentBounds.X);
				ObstaclePosition.Y = EnvironmentCenter.Y + FMath::RandRange(-EnvironmentBounds.Y, EnvironmentBounds.Y);
				ObstaclePosition.Z = EnvironmentCenter.Z;
				ObstaclePosition.Z = FindGroundLevel(ObstaclePosition);
			}
			
			// Ensure obstacle is properly above ground
			ObstaclePosition.Z += 10.0f;
			
			// Check if position is valid (avoids agents and targets)
			ValidPosition = IsValidObstaclePosition(ObstaclePosition, AgentLocation, 150.0f) && 
							IsValidObstaclePosition(ObstaclePosition, TargetLocation, 150.0f);
			
			Attempts++;
		} while (!ValidPosition && Attempts < MaxAttempts);

		// Create obstacle if we found a valid position
		if (ValidPosition)
		{
			AFPSObstacleActor* NewObstacle = CreateObstacleAtPosition(ObstaclePosition);
			if (NewObstacle)
			{
				CurrentObstacles.Add(NewObstacle);
			}
		}
	}

	// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Initialized %d obstacles with smart placement (avoiding agents/targets)"), CurrentObstacles.Num());
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
		// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Regenerated obstacles in dynamic mode"));
	}
	else
	{
		// UE_LOG(LogTemp, Warning, TEXT("FPSObstacleManager: RegenerateObstacles called but not in dynamic mode"));
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
		if (LocationVolume)
		{
			// Use LocationVolume for positioning
			FVector VolumeOrigin = LocationVolume->GetActorLocation();
			FVector VolumeExtent;
			LocationVolume->GetActorBounds(false, VolumeOrigin, VolumeExtent);
			
			// Generate random point within volume bounds
			Position.X = FMath::RandRange(VolumeOrigin.X - VolumeExtent.X, VolumeOrigin.X + VolumeExtent.X);
			Position.Y = FMath::RandRange(VolumeOrigin.Y - VolumeExtent.Y, VolumeOrigin.Y + VolumeExtent.Y);
			Position.Z = VolumeOrigin.Z + VolumeExtent.Z; // Start from top of volume
			
			// Find ground level
			Position.Z = FindGroundLevel(Position);
		}
		else
		{
			// Fallback to environment bounds
			Position.X = EnvironmentCenter.X + FMath::RandRange(-EnvironmentBounds.X, EnvironmentBounds.X);
			Position.Y = EnvironmentCenter.Y + FMath::RandRange(-EnvironmentBounds.Y, EnvironmentBounds.Y);
			Position.Z = EnvironmentCenter.Z;
			Position.Z = FindGroundLevel(Position);
		}
		
		// Ensure obstacle is properly above ground
		Position.Z += 10.0f; // Small offset to prevent clipping
		
		Attempts++;
	} while (!IsValidObstaclePosition(Position, AvoidLocation, AvoidRadius) && Attempts < MaxAttempts);

	return Position;
}

bool UFPSObstacleManager::IsValidObstaclePosition(const FVector& Position, const FVector& AvoidLocation, float AvoidRadius) const
{
	// Check if position is within bounds
	if (LocationVolume)
	{
		// Check if position is within volume bounds
		FVector VolumeOrigin = LocationVolume->GetActorLocation();
		FVector VolumeExtent;
		LocationVolume->GetActorBounds(false, VolumeOrigin, VolumeExtent);
		
		if (Position.X < VolumeOrigin.X - VolumeExtent.X || Position.X > VolumeOrigin.X + VolumeExtent.X ||
			Position.Y < VolumeOrigin.Y - VolumeExtent.Y || Position.Y > VolumeOrigin.Y + VolumeExtent.Y)
		{
			return false;
		}
	}
	else
	{
		// Fallback to environment bounds
		if (Position.X < EnvironmentCenter.X - EnvironmentBounds.X || Position.X > EnvironmentCenter.X + EnvironmentBounds.X ||
			Position.Y < EnvironmentCenter.Y - EnvironmentBounds.Y || Position.Y > EnvironmentCenter.Y + EnvironmentBounds.Y)
		{
			return false;
		}
	}

	// Check distance from avoid location (agents/targets)
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
		// UE_LOG(LogTemp, Warning, TEXT("FPSObstacleManager: Cannot create obstacle - World: %s, ObstacleClass: %s"), 
			// GetWorld() ? TEXT("Valid") : TEXT("NULL"), ObstacleClass ? TEXT("Valid") : TEXT("NULL"));
		return nullptr;
	}

	// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Creating obstacle at position: %s"), *Position.ToString());

	// Spawn obstacle
	FActorSpawnParameters SpawnParams;
	SpawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
	
	AFPSObstacleActor* NewObstacle = GetWorld()->SpawnActor<AFPSObstacleActor>(ObstacleClass, Position, FRotator::ZeroRotator, SpawnParams);
	
	if (NewObstacle)
	{
		// Calculate obstacle dimensions based on volume
		float VolumeHeight = 1000.0f; // Default height if no volume
		float VolumeWidthX = 200.0f;  // Default width if no volume
		float VolumeWidthY = 200.0f;  // Default width if no volume
		
		// Get dimensions from location volume if available
		if (LocationVolume)
		{
			FVector VolumeOrigin = LocationVolume->GetActorLocation();
			FVector VolumeExtent;
			LocationVolume->GetActorBounds(false, VolumeOrigin, VolumeExtent);
			VolumeHeight = VolumeExtent.Z * 2.0f; // Full height of volume
			VolumeWidthX = VolumeExtent.X * 2.0f;  // Full width of volume
			VolumeWidthY = VolumeExtent.Y * 2.0f;  // Full width of volume
		}
		else
		{
			// Use environment bounds as fallback
			VolumeHeight = EnvironmentBounds.Z * 2.0f;
			VolumeWidthX = EnvironmentBounds.X * 2.0f;
			VolumeWidthY = EnvironmentBounds.Y * 2.0f;
		}
		
		// Create obstacles that span the full height and are randomly wide
		float WidthX = FMath::RandRange(MinObstacleSize, FMath::Min(MaxObstacleSize, VolumeWidthX * 0.8f));
		float WidthY = FMath::RandRange(MinObstacleSize, FMath::Min(MaxObstacleSize, VolumeWidthY * 0.8f));
		float Height = VolumeHeight; // Use full volume height
		float Depth = FMath::RandRange(WidthX * 0.1f, WidthX * 0.3f); // Thin walls
		
		NewObstacle->InitializeObstacle(WidthX, Height, WidthY);
		
		// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Created obstacle at %s with WX:%f WY:%f H:%f D:%f (Volume: %fx%fx%f)"), 
			// *Position.ToString(), WidthX, WidthY, Height, Depth, VolumeWidthX, VolumeWidthY, VolumeHeight);
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

void UFPSObstacleManager::SetLocationVolume(AVolume* NewLocationVolume)
{
	LocationVolume = NewLocationVolume;
	// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: LocationVolume set to %s"), 
		// LocationVolume ? *LocationVolume->GetName() : TEXT("NULL"));
}

void UFPSObstacleManager::FindAndSetLocationVolume()
{
	if (!GetWorld())
	{
		// UE_LOG(LogTemp, Warning, TEXT("FPSObstacleManager: No World available"));
		return;
	}

	// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Searching for volumes in world..."));

	// Find the first Volume in the world
	int32 VolumeCount = 0;
	for (TActorIterator<AVolume> ActorItr(GetWorld()); ActorItr; ++ActorItr)
	{
		AVolume* FoundVolume = *ActorItr;
		VolumeCount++;
		// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Found Volume %d: %s (Class: %s)"), 
			// VolumeCount, *FoundVolume->GetName(), *FoundVolume->GetClass()->GetName());
		
		if (IsValid(FoundVolume))
		{
			SetLocationVolume(FoundVolume);
			// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Using Volume: %s"), *FoundVolume->GetName());
			return;
		}
	}

	// UE_LOG(LogTemp, Warning, TEXT("FPSObstacleManager: No valid Volume found (checked %d volumes), using environment bounds"), VolumeCount);
}

void UFPSObstacleManager::ShuffleObstaclePositions()
{
	if (ObstacleMode != EObstacleMode::Dynamic)
	{
		// UE_LOG(LogTemp, Warning, TEXT("FPSObstacleManager: ShuffleObstaclePositions called but not in dynamic mode"));
		return;
	}

	// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Shuffling %d obstacle positions"), CurrentObstacles.Num());

	// Store current obstacle count
	int32 ObstacleCount = CurrentObstacles.Num();
	
	// Clear existing obstacles
	ClearObstacles();
	
	// Recreate obstacles with new random positions
	for (int32 i = 0; i < ObstacleCount; i++)
	{
		FVector ObstaclePosition = GenerateRandomObstaclePosition(FVector::ZeroVector, 0.0f);
		AFPSObstacleActor* NewObstacle = CreateObstacleAtPosition(ObstaclePosition);
		if (NewObstacle)
		{
			CurrentObstacles.Add(NewObstacle);
		}
	}

	// UE_LOG(LogTemp, Log, TEXT("FPSObstacleManager: Shuffled %d obstacles to new positions"), CurrentObstacles.Num());
}

