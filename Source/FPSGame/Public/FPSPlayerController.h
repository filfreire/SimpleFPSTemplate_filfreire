// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "FPSPlayerController.generated.h"

// Forward declarations
class AFPSSpectatorCamera;

/**
 *
 */
UCLASS()
class FPSGAME_API AFPSPlayerController : public APlayerController
{
	GENERATED_BODY()

public:
	// Constructor
	AFPSPlayerController();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

	// Called to bind functionality to input
	virtual void SetupInputComponent() override;

	// Spectator mode variables
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Spectator")
	bool bIsSpectating = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Spectator")
	AFPSSpectatorCamera* SpectatorCamera = nullptr;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Spectator")
	APawn* OriginalPawn = nullptr;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Spectator")
	TSubclassOf<AFPSSpectatorCamera> SpectatorCameraClass;

	// Spectator mode functions
	UFUNCTION(BlueprintCallable, Category = "Spectator")
	void ToggleSpectatorMode();

	UFUNCTION(BlueprintCallable, Category = "Spectator")
	void EnterSpectatorMode();

	UFUNCTION(BlueprintCallable, Category = "Spectator")
	void ExitSpectatorMode();

	// Spectator movement functions
	void SpectatorMoveForward(float Value);
	void SpectatorMoveRight(float Value);
	void SpectatorMoveUp(float Value);
	void SpectatorTurn(float Value);
	void SpectatorLookUp(float Value);

public:
    UFUNCTION(BlueprintImplementableEvent, Category = "PlayerController")
    void OnMissionCompleted(APawn* InstigatorPawn, bool bMissionSuccess);

};
