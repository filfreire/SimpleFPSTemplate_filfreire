// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Components/StaticMeshComponent.h"
#include "Components/BoxComponent.h"
#include "FPSObstacleActor.generated.h"

/**
 * Base obstacle actor that can be used in both static and dynamic modes
 * Provides collision detection and visual representation
 */
UCLASS()
class FPSGAME_API AFPSObstacleActor : public AActor
{
	GENERATED_BODY()
	
public:	
	AFPSObstacleActor();

protected:
	virtual void BeginPlay() override;

public:	
	virtual void Tick(float DeltaTime) override;

	// Static mesh component for visual representation
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components")
	UStaticMeshComponent* ObstacleMesh;

	// Box collision component for collision detection
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components")
	UBoxComponent* CollisionBox;

	// Obstacle properties
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle")
	float ObstacleHeight = 200.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle")
	float ObstacleWidth = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Obstacle")
	float ObstacleDepth = 100.0f;

	// Check if a location is blocked by this obstacle
	UFUNCTION(BlueprintCallable, Category = "Obstacle")
	bool IsLocationBlocked(const FVector& Location, float AgentRadius = 50.0f) const;

	// Get the bounds of this obstacle
	UFUNCTION(BlueprintCallable, Category = "Obstacle")
	FBox GetObstacleBounds() const;

	// Initialize obstacle with given dimensions
	UFUNCTION(BlueprintCallable, Category = "Obstacle")
	void InitializeObstacle(float Width, float Height, float Depth);

private:
	// Update collision box size based on obstacle dimensions
	void UpdateCollisionBox();
};

