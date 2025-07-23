// Fill out your copyright notice in the Description page of Project Settings.

#include "FPSPlayerController.h"
#include "FPSSpectatorCamera.h"
#include "Engine/World.h"
#include "Components/InputComponent.h"
#include "GameFramework/Pawn.h"

AFPSPlayerController::AFPSPlayerController()
{
	// Set default spectator camera class
	SpectatorCameraClass = AFPSSpectatorCamera::StaticClass();
}

void AFPSPlayerController::BeginPlay()
{
	Super::BeginPlay();

	// Store reference to original pawn
	OriginalPawn = GetPawn();

	// Create spectator camera if class is set
	if (SpectatorCameraClass && GetWorld())
	{
		FActorSpawnParameters SpawnParams;
		SpawnParams.Owner = this;
		SpawnParams.Instigator = GetInstigator();
		
		SpectatorCamera = GetWorld()->SpawnActor<AFPSSpectatorCamera>(SpectatorCameraClass, SpawnParams);
		
		if (SpectatorCamera)
		{
			UE_LOG(LogTemp, Log, TEXT("Spectator camera created successfully"));
		}
		else
		{
			UE_LOG(LogTemp, Warning, TEXT("Failed to create spectator camera"));
		}
	}
}

void AFPSPlayerController::SetupInputComponent()
{
	Super::SetupInputComponent();

	// Bind spectator toggle key (F for spectator mode)
	InputComponent->BindAction("ToggleSpectator", IE_Pressed, this, &AFPSPlayerController::ToggleSpectatorMode);

	// Bind spectator movement keys (only active when spectating)
	InputComponent->BindAxis("SpectatorMoveForward", this, &AFPSPlayerController::SpectatorMoveForward);
	InputComponent->BindAxis("SpectatorMoveRight", this, &AFPSPlayerController::SpectatorMoveRight);
	InputComponent->BindAxis("SpectatorMoveUp", this, &AFPSPlayerController::SpectatorMoveUp);
	InputComponent->BindAxis("SpectatorTurn", this, &AFPSPlayerController::SpectatorTurn);
	InputComponent->BindAxis("SpectatorLookUp", this, &AFPSPlayerController::SpectatorLookUp);
}

void AFPSPlayerController::ToggleSpectatorMode()
{
	if (bIsSpectating)
	{
		ExitSpectatorMode();
	}
	else
	{
		EnterSpectatorMode();
	}
}

void AFPSPlayerController::EnterSpectatorMode()
{
	if (bIsSpectating || !SpectatorCamera)
	{
		return;
	}

	// Store current pawn reference
	OriginalPawn = GetPawn();
	
	if (OriginalPawn)
	{
		// Disable input on the original pawn
		OriginalPawn->DisableInput(this);
		
		// Set view target to spectator camera
		SetViewTargetWithBlend(SpectatorCamera, 0.5f, EViewTargetBlendFunction::VTBlend_Cubic);
		
		bIsSpectating = true;
		
		UE_LOG(LogTemp, Log, TEXT("Entered spectator mode"));
	}
}

void AFPSPlayerController::ExitSpectatorMode()
{
	if (!bIsSpectating || !OriginalPawn)
	{
		return;
	}

	// Re-enable input on the original pawn
	OriginalPawn->EnableInput(this);
	
	// Set view target back to original pawn
	SetViewTargetWithBlend(OriginalPawn, 0.5f, EViewTargetBlendFunction::VTBlend_Cubic);
	
	bIsSpectating = false;
	
	UE_LOG(LogTemp, Log, TEXT("Exited spectator mode"));
}

void AFPSPlayerController::SpectatorMoveForward(float Value)
{
	if (bIsSpectating && SpectatorCamera)
	{
		SpectatorCamera->MoveForward(Value);
	}
}

void AFPSPlayerController::SpectatorMoveRight(float Value)
{
	if (bIsSpectating && SpectatorCamera)
	{
		SpectatorCamera->MoveRight(Value);
	}
}

void AFPSPlayerController::SpectatorMoveUp(float Value)
{
	if (bIsSpectating && SpectatorCamera)
	{
		SpectatorCamera->MoveUp(Value);
	}
}

void AFPSPlayerController::SpectatorTurn(float Value)
{
	if (bIsSpectating && SpectatorCamera)
	{
		SpectatorCamera->Turn(Value);
	}
}

void AFPSPlayerController::SpectatorLookUp(float Value)
{
	if (bIsSpectating && SpectatorCamera)
	{
		SpectatorCamera->LookUp(Value);
	}
}

