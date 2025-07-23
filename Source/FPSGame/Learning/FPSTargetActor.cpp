// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "FPSTargetActor.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/Engine.h"

AFPSTargetActor::AFPSTargetActor()
{
	PrimaryActorTick.bCanEverTick = true;

	// Create and setup mesh component
	MeshComponent = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("MeshComponent"));
	RootComponent = MeshComponent;

	// Set a basic cube mesh as default
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube"));
	if (CubeMesh.Succeeded())
	{
		MeshComponent->SetStaticMesh(CubeMesh.Object);
	}

	// Set default material color to red for visibility
	MeshComponent->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
	// Set default scale
	SetActorScale3D(FVector(0.5f, 0.5f, 0.5f));
}

void AFPSTargetActor::BeginPlay()
{
	Super::BeginPlay();
	
	UE_LOG(LogTemp, Log, TEXT("FPSTargetActor spawned at location: %s"), *GetActorLocation().ToString());
}

void AFPSTargetActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	// Optional: Add visual effects like rotation or pulsing
	AddActorLocalRotation(FRotator(0, 45.0f * DeltaTime, 0));
}

void AFPSTargetActor::ResetToRandomLocation(FVector Center, FVector Bounds)
{
	// Generate random location within bounds
	FVector RandomLocation = Center + FVector(
		FMath::RandRange(-Bounds.X, Bounds.X),
		FMath::RandRange(-Bounds.Y, Bounds.Y),
		FMath::RandRange(-Bounds.Z, Bounds.Z)
	);

	SetActorLocation(RandomLocation);
	
	UE_LOG(LogTemp, Log, TEXT("FPSTargetActor reset to location: %s"), *RandomLocation.ToString());
}

bool AFPSTargetActor::IsLocationWithinReach(FVector Location, float Distance) const
{
	float ActualDistance = FVector::Dist(GetActorLocation(), Location);
	return ActualDistance <= (Distance > 0 ? Distance : ReachDistance);
} 