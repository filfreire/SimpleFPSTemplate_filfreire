// Fill out your copyright notice in the Description page of Project Settings.


#include "FPSGameState.h"
#include "FPSPlayerController.h"
#include "Runtime\Engine\Classes\Engine\World.h"

void AFPSGameState::MulticastOnMissionComplete_Implementation(APawn* InstigatorPawn, bool bMissionSuccess)
{
	for (FConstPlayerControllerIterator It = GetWorld()->GetPlayerControllerIterator(); It; It++) {
		AFPSPlayerController* PC = Cast<AFPSPlayerController>(It->Get());
		if (PC && PC->IsLocalController())
		{
			PC->OnMissionCompleted(InstigatorPawn, bMissionSuccess);

			APawn* Pawn = PC->GetPawn();
			if (Pawn && Pawn->IsLocallyControlled())
			{
				Pawn->DisableInput(nullptr);
			}
		}
	}
}