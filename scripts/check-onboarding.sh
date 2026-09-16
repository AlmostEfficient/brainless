#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
check_binary=$(mktemp -t brainless-onboarding)
trap 'rm -f "$check_binary"' EXIT
swiftc Brainless/Models/FitnessEnums.swift Brainless/Models/ProfileModels.swift Brainless/Features/Onboarding/ProfileDrafts.swift Brainless/Features/Onboarding/ProfileDraftAdapters.swift Brainless/App/PersistenceRecords.swift Brainless/Persistence/Stores.swift Brainless/Features/Onboarding/OnboardingViewModel.swift Tests/OnboardingChecks.swift -o "$check_binary"
"$check_binary"
