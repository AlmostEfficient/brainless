#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
if (( $# == 0 )); then set -- Tests/Fixtures/workout.json; fi
check_binary=$(mktemp -t brainless-contract)
trap 'rm -f "$check_binary"' EXIT
swiftc Brainless/Models/FitnessEnums.swift Brainless/Models/ProfileModels.swift Brainless/Models/TextWorkoutModels.swift Brainless/UIComponents/DisplayNames.swift Brainless/Services/WorkoutGenerationService.swift Brainless/Services/ExerciseAssetURLBuilder.swift Tests/WorkoutContractChecks.swift -o "$check_binary"
"$check_binary" "$@"
