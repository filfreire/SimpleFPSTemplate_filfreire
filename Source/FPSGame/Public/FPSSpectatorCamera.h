// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "FPSSpectatorCamera.generated.h"

UCLASS()
class FPSGAME_API AFPSSpectatorCamera : public AActor
{
	GENERATED_BODY()
	
public:	
	AFPSSpectatorCamera();

protected:
	virtual void BeginPlay() override;

	/** Camera component for spectating */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Camera")
	UCameraComponent* CameraComponent;

	/** Spring arm for smooth camera movement */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Camera")
	USpringArmComponent* SpringArmComponent;

	/** Movement speed for the spectator camera */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement")
	float MovementSpeed = 1000.0f;

	/** Look sensitivity for the spectator camera */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement")
	float LookSensitivity = 2.0f;

public:	
	virtual void Tick(float DeltaTime) override;

	/** Handle movement input */
	UFUNCTION(BlueprintCallable, Category = "Movement")
	void MoveForward(float Value);

	UFUNCTION(BlueprintCallable, Category = "Movement")
	void MoveRight(float Value);

	UFUNCTION(BlueprintCallable, Category = "Movement")
	void MoveUp(float Value);

	/** Handle look input */
	UFUNCTION(BlueprintCallable, Category = "Movement")
	void Turn(float Value);

	UFUNCTION(BlueprintCallable, Category = "Movement")
	void LookUp(float Value);

	/** Get the camera component for view targeting */
	UFUNCTION(BlueprintCallable, Category = "Camera")
	UCameraComponent* GetSpectatorCamera() const { return CameraComponent; }
}; 