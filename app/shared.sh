#!/usr/bin/env bash

__error() {
	echo "::error::${@:2}"
	exit 9;
}
__warning() {
	echo "::warning::${@:2}"
}
__info() {
	echo "::debug::${@:2}"
}

__set_output() {
	echo "::set-output name=$1::${@:2}";
}