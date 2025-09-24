// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "Learning/FPSObstacleActor.h"
#include "Components/StaticMeshComponent.h"
#include "Components/BoxComponent.h"
#include "Engine/Engine.h"

AFPSObstacleActor::AFPSObstacleActor()
{
	PrimaryActorTick.bCanEverTick = false;

	// Create root component
	RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("RootComponent"));

	// Create static mesh component
	ObstacleMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ObstacleMesh"));
	ObstacleMesh->SetupAttachment(RootComponent);

	// Create collision box component
	CollisionBox = CreateDefaultSubobject<UBoxComponent>(TEXT("CollisionBox"));
	CollisionBox->SetupAttachment(RootComponent);
	CollisionBox->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	CollisionBox->SetCollisionResponseToAllChannels(ECR_Block);
	CollisionBox->SetCollisionResponseToChannel(ECC_Pawn, ECR_Block);

	// Set default mesh (basic cube)
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube"));
	if (CubeMesh.Succeeded())
	{
		ObstacleMesh->SetStaticMesh(CubeMesh.Object);
	}

	// Initialize with default dimensions
	InitializeObstacle(ObstacleWidth, ObstacleHeight, ObstacleDepth);
}

void AFPSObstacleActor::BeginPlay()
{
	Super::BeginPlay();
	
	// Update collision box on begin play
	UpdateCollisionBox();
}

void AFPSObstacleActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
}

bool AFPSObstacleActor::IsLocationBlocked(const FVector& Location, float AgentRadius) const
{
	FBox ObstacleBounds = GetObstacleBounds();
	
	// Expand bounds by agent radius
	FVector ExpandedMin = ObstacleBounds.Min - FVector(AgentRadius);
	FVector ExpandedMax = ObstacleBounds.Max + FVector(AgentRadius);
	
	// Check if location is within expanded bounds
	return Location.X >= ExpandedMin.X && Location.X <= ExpandedMax.X &&
		   Location.Y >= ExpandedMin.Y && Location.Y <= ExpandedMax.Y &&
		   Location.Z >= ExpandedMin.Z && Location.Z <= ExpandedMax.Z;
}

FBox AFPSObstacleActor::GetObstacleBounds() const
{
	FVector Location = GetActorLocation();
	FVector HalfExtent = FVector(ObstacleWidth * 0.5f, ObstacleDepth * 0.5f, ObstacleHeight * 0.5f);
	
	return FBox(Location - HalfExtent, Location + HalfExtent);
}

void AFPSObstacleActor::InitializeObstacle(float Width, float Height, float Depth)
{
	ObstacleWidth = Width;
	ObstacleHeight = Height;
	ObstacleDepth = Depth;
	
	// Update mesh scale
	if (ObstacleMesh)
	{
		ObstacleMesh->SetRelativeScale3D(FVector(Width / 100.0f, Depth / 100.0f, Height / 100.0f));
	}
	
	UpdateCollisionBox();
}

void AFPSObstacleActor::UpdateCollisionBox()
{
	if (CollisionBox)
	{
		CollisionBox->SetBoxExtent(FVector(ObstacleWidth * 0.5f, ObstacleDepth * 0.5f, ObstacleHeight * 0.5f));
	}
}

