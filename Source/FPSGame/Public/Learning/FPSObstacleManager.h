// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "Components/ActorComponent.h"
#include "CoreMinimal.h"
#include "FPSObstacleActor.h"
#include "FPSObstacleManager.generated.h"
#include "GameFramework/Volume.h"
#include "Learning/ObstacleTypes.h"

/**
 * Manages obstacles in the training environment
 * Supports both static and dynamic modes
 */
UCLASS(ClassGroup = (Custom), meta = (BlueprintSpawnableComponent))
class FPSGAME_API UFPSObstacleManager : public UActorComponent
{
	GENERATED_BODY()

  public:
	UFPSObstacleManager();

  protected:
	virtual void BeginPlay() override;

  public:
	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
	                           FActorComponentTickFunction* ThisTickFunction) override;

	// Obstacle mode
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle Management")
	EObstacleMode ObstacleMode = EObstacleMode::Static;

	// Obstacle configuration
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle Configuration")
	int32 MaxObstacles = 24;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle Configuration")
	float MinObstacleSize = 60.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle Configuration")
	float MaxObstacleSize = 120.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle Configuration")
	float MinDistanceFromAgents = 200.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle Configuration")
	float MinDistanceFromTarget = 200.0f;

	// Location volume for obstacle placement (if available)
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Environment")
	AVolume* LocationVolume = nullptr;

	// Fallback environment bounds for obstacle placement (used if no LocationVolume)
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Environment")
	FVector EnvironmentCenter = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Environment")
	FVector EnvironmentBounds = FVector(2000.0f, 2000.0f, 0.0f);

	// Obstacle class to spawn
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle Configuration")
	TSubclassOf<AFPSObstacleActor> ObstacleClass = AFPSObstacleActor::StaticClass();

	// Current obstacles
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Obstacle Management")
	TArray<AFPSObstacleActor*> CurrentObstacles;

	// Initialize obstacles for the environment
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	void InitializeObstacles();

	// Initialize obstacles with smart placement around agents and targets
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	void InitializeObstaclesWithSmartPlacement(const FVector& AgentLocation, const FVector& TargetLocation);

	// Set the location volume for obstacle placement
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	void SetLocationVolume(AVolume* NewLocationVolume);

	// Find and set location volume automatically
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	void FindAndSetLocationVolume();

	// Clear all obstacles
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	void ClearObstacles();

	// Regenerate obstacles (for dynamic mode)
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	void RegenerateObstacles();

	// Check if a location is blocked by any obstacle
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	bool IsLocationBlocked(const FVector& Location, float AgentRadius = 50.0f) const;

	// Get all obstacles
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	TArray<AFPSObstacleActor*> GetObstacles() const { return CurrentObstacles; }

	// Set obstacle mode
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	void SetObstacleMode(EObstacleMode NewMode);

	// Shuffle obstacle positions (for dynamic mode)
	UFUNCTION(BlueprintCallable, Category = "Obstacle Management")
	void ShuffleObstaclePositions();

  private:
	// Timer for shuffling obstacles in dynamic mode
	float ShuffleTimer = 0.0f;
	// Generate a random position for an obstacle
	FVector GenerateRandomObstaclePosition(const FVector& AvoidLocation, float AvoidRadius) const;

	// Check if a position is valid for obstacle placement
	bool IsValidObstaclePosition(const FVector& Position, const FVector& AvoidLocation, float AvoidRadius) const;

	// Create a single obstacle at the given position
	AFPSObstacleActor* CreateObstacleAtPosition(const FVector& Position);

	// Find ground level at a given position using line trace
	float FindGroundLevel(const FVector& Position) const;
};
