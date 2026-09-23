#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
if (( $# == 0 )); then set -- Tests/Fixtures/workout.json; fi
check_binary=$(mktemp -t brainless-stream)
trap 'rm -f "$check_binary"' EXIT
swiftc Brainless/Models/FitnessEnums.swift Brainless/Models/ProfileModels.swift Brainless/Services/WorkoutGenerationService.swift Brainless/Services/RemoteWorkoutGenerationService.swift Brainless/Networking/APIClient.swift Brainless/Networking/APIError.swift Brainless/Networking/APITokenProvider.swift Tests/WorkoutStreamingChecks.swift -o "$check_binary"
"$check_binary" "$1"
