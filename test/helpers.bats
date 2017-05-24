#!/usr/bin/env bats

load ../bin/utils/helpers

# make sure functions exist

@test "prompt_user() is defined" {
    result="$(type -t prompt_user)"

    [ "$result" == "function" ]
}

@test "brew_install() is defined" {
    result="$(type -t brew_install)"

    [ "$result" == "function" ]
}

@test "brew_cask_install() is defined" {
    result="$(type -t brew_cask_install)"

    [ "$result" == "function" ]
}

@test "os_eligible() is defined" {
    result="$(type -t os_eligible)"

    [ "$result" == "function" ]
}

@test "log() is defined" {
    result="$(type -t log)"

    [ "$result" == "function" ]
}

# test log function

@test "log() sends output to ~/.setup.log and format is correct" {
    result="$(log x)"

    [ -f "$HOME/.setup.log" ]

    rm -rf "$HOME/.setup.log"

    [ ! -f "$HOME/.setup.log" ]
}
