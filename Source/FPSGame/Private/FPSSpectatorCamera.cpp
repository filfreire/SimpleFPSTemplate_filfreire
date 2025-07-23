// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "FPSSpectatorCamera.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Components/SceneComponent.h"

AFPSSpectatorCamera::AFPSSpectatorCamera()
{
	PrimaryActorTick.bCanEverTick = true;

	// Create root component
	RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("RootComponent"));

	// Create spring arm component
	SpringArmComponent = CreateDefaultSubobject<USpringArmComponent>(TEXT("SpringArm"));
	SpringArmComponent->SetupAttachment(RootComponent);
	SpringArmComponent->TargetArmLength = 0.0f; // No arm length for direct camera control
	SpringArmComponent->bUsePawnControlRotation = true;
	SpringArmComponent->bInheritPitch = true;
	SpringArmComponent->bInheritYaw = true;
	SpringArmComponent->bInheritRoll = false;

	// Create camera component
	CameraComponent = CreateDefaultSubobject<UCameraComponent>(TEXT("SpectatorCamera"));
	CameraComponent->SetupAttachment(SpringArmComponent);
	CameraComponent->bUsePawnControlRotation = false; // Spring arm will handle rotation
}

void AFPSSpectatorCamera::BeginPlay()
{
	Super::BeginPlay();
	
	// Position the camera at a good overview location by default
	SetActorLocation(FVector(0, 0, 1000));
	SetActorRotation(FRotator(-45, 0, 0));
}

void AFPSSpectatorCamera::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
}

void AFPSSpectatorCamera::MoveForward(float Value)
{
	if (Value != 0.0f)
	{
		// Move in the direction the camera is facing
		FVector Direction = GetActorForwardVector();
		AddActorWorldOffset(Direction * Value * MovementSpeed * GetWorld()->GetDeltaSeconds());
	}
}

void AFPSSpectatorCamera::MoveRight(float Value)
{
	if (Value != 0.0f)
	{
		// Move in the right direction relative to camera
		FVector Direction = GetActorRightVector();
		AddActorWorldOffset(Direction * Value * MovementSpeed * GetWorld()->GetDeltaSeconds());
	}
}

void AFPSSpectatorCamera::MoveUp(float Value)
{
	if (Value != 0.0f)
	{
		// Move up/down in world space
		FVector Direction = FVector::UpVector;
		AddActorWorldOffset(Direction * Value * MovementSpeed * GetWorld()->GetDeltaSeconds());
	}
}

void AFPSSpectatorCamera::Turn(float Value)
{
	if (Value != 0.0f)
	{
		// Add yaw rotation
		AddActorWorldRotation(FRotator(0, Value * LookSensitivity, 0));
	}
}

void AFPSSpectatorCamera::LookUp(float Value)
{
	if (Value != 0.0f)
	{
		// Add pitch rotation, but clamp to prevent over-rotation
		FRotator CurrentRotation = GetActorRotation();
		float NewPitch = FMath::ClampAngle(CurrentRotation.Pitch + (Value * LookSensitivity), -90.0f, 90.0f);
		SetActorRotation(FRotator(NewPitch, CurrentRotation.Yaw, CurrentRotation.Roll));
	}
} 