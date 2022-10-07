// Copyright(C) 2019-2021 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
// miniaudio (https://github.com/dr-soft/miniaudio)
// is licensed under the unlicense and, are thus, in the publiic domain.
module c

pub fn translate_error_code(code int) string {
	match code {
		C.MA_SUCCESS {
			return 'SUCCESS'
		}
		// General errors.
		C.MA_ERROR {
			// A generic error.
			return 'MA_ERROR'
		}
		C.MA_INVALID_ARGS {
			return 'MA_INVALID_ARGS'
		}
		C.MA_INVALID_OPERATION {
			return 'MA_INVALID_OPERATION'
		}
		C.MA_OUT_OF_MEMORY {
			return 'MA_OUT_OF_MEMORY'
		}
		C.MA_OUT_OF_RANGE {
			return 'MA_OUT_OF_RANGE'
		}
		C.MA_ACCESS_DENIED {
			return 'MA_ACCESS_DENIED'
		}
		C.MA_DOES_NOT_EXIST {
			return 'MA_DOES_NOT_EXIST'
		}
		C.MA_ALREADY_EXISTS {
			return 'MA_ALREADY_EXISTS'
		}
		C.MA_TOO_MANY_OPEN_FILES {
			return 'MA_TOO_MANY_OPEN_FILES'
		}
		C.MA_INVALID_FILE {
			return 'MA_INVALID_FILE'
		}
		C.MA_TOO_BIG {
			return 'MA_TOO_BIG'
		}
		C.MA_PATH_TOO_LONG {
			return 'MA_PATH_TOO_LONG'
		}
		C.MA_NAME_TOO_LONG {
			return 'MA_NAME_TOO_LONG'
		}
		C.MA_NOT_DIRECTORY {
			return 'MA_NOT_DIRECTORY'
		}
		C.MA_IS_DIRECTORY {
			return 'MA_IS_DIRECTORY'
		}
		C.MA_DIRECTORY_NOT_EMPTY {
			return 'MA_DIRECTORY_NOT_EMPTY'
		}
		C.MA_AT_END {
			return 'MA_AT_END'
		}
		C.MA_NO_SPACE {
			return 'MA_NO_SPACE'
		}
		C.MA_BUSY {
			return 'MA_BUSY'
		}
		C.MA_IO_ERROR {
			return 'MA_IO_ERROR'
		}
		C.MA_INTERRUPT {
			return 'MA_INTERRUPT'
		}
		C.MA_UNAVAILABLE {
			return 'MA_UNAVAILABLE'
		}
		C.MA_ALREADY_IN_USE {
			return 'MA_ALREADY_IN_USE'
		}
		C.MA_BAD_ADDRESS {
			return 'MA_BAD_ADDRESS'
		}
		C.MA_BAD_SEEK {
			return 'MA_BAD_SEEK'
		}
		C.MA_BAD_PIPE {
			return 'MA_BAD_PIPE'
		}
		C.MA_DEADLOCK {
			return 'MA_DEADLOCK'
		}
		C.MA_TOO_MANY_LINKS {
			return 'MA_TOO_MANY_LINKS'
		}
		C.MA_NOT_IMPLEMENTED {
			return 'MA_NOT_IMPLEMENTED'
		}
		C.MA_NO_MESSAGE {
			return 'MA_NO_MESSAGE'
		}
		C.MA_BAD_MESSAGE {
			return 'MA_BAD_MESSAGE'
		}
		C.MA_NO_DATA_AVAILABLE {
			return 'MA_NO_DATA_AVAILABLE'
		}
		C.MA_INVALID_DATA {
			return 'MA_INVALID_DATA'
		}
		C.MA_TIMEOUT {
			return 'MA_TIMEOUT'
		}
		C.MA_NO_NETWORK {
			return 'MA_NO_NETWORK'
		}
		C.MA_NOT_UNIQUE {
			return 'MA_NOT_UNIQUE'
		}
		C.MA_NOT_SOCKET {
			return 'MA_NOT_SOCKET'
		}
		C.MA_NO_ADDRESS {
			return 'MA_NO_ADDRESS'
		}
		C.MA_BAD_PROTOCOL {
			return 'MA_BAD_PROTOCOL'
		}
		C.MA_PROTOCOL_UNAVAILABLE {
			return 'MA_PROTOCOL_UNAVAILABLE'
		}
		C.MA_PROTOCOL_NOT_SUPPORTED {
			return 'MA_PROTOCOL_NOT_SUPPORTED'
		}
		C.MA_PROTOCOL_FAMILY_NOT_SUPPORTED {
			return 'MA_PROTOCOL_FAMILY_NOT_SUPPORTED'
		}
		C.MA_ADDRESS_FAMILY_NOT_SUPPORTED {
			return 'MA_ADDRESS_FAMILY_NOT_SUPPORTED'
		}
		C.MA_SOCKET_NOT_SUPPORTED {
			return 'MA_SOCKET_NOT_SUPPORTED'
		}
		C.MA_CONNECTION_RESET {
			return 'MA_CONNECTION_RESET'
		}
		C.MA_ALREADY_CONNECTED {
			return 'MA_ALREADY_CONNECTED'
		}
		C.MA_NOT_CONNECTED {
			return 'MA_NOT_CONNECTED'
		}
		C.MA_CONNECTION_REFUSED {
			return 'MA_CONNECTION_REFUSED'
		}
		C.MA_NO_HOST {
			return 'MA_NO_HOST'
		}
		C.MA_IN_PROGRESS {
			return 'MA_IN_PROGRESS'
		}
		C.MA_CANCELLED {
			return 'MA_CANCELLED'
		}
		C.MA_MEMORY_ALREADY_MAPPED {
			return 'MA_MEMORY_ALREADY_MAPPED'
		}
		// General miniaudio-specific errors.
		C.MA_FORMAT_NOT_SUPPORTED {
			return 'MA_FORMAT_NOT_SUPPORTED'
		}
		C.MA_DEVICE_TYPE_NOT_SUPPORTED {
			return 'MA_DEVICE_TYPE_NOT_SUPPORTED'
		}
		C.MA_SHARE_MODE_NOT_SUPPORTED {
			return 'MA_SHARE_MODE_NOT_SUPPORTED'
		}
		C.MA_NO_BACKEND {
			return 'MA_NO_BACKEND'
		}
		C.MA_NO_DEVICE {
			return 'MA_NO_DEVICE'
		}
		C.MA_API_NOT_FOUND {
			return 'MA_API_NOT_FOUND'
		}
		C.MA_INVALID_DEVICE_CONFIG {
			return 'MA_INVALID_DEVICE_CONFIG'
		}
		C.MA_LOOP {
			return 'MA_LOOP'
		}
		// State errors.
		C.MA_DEVICE_NOT_INITIALIZED {
			return 'MA_DEVICE_NOT_INITIALIZED'
		}
		C.MA_DEVICE_ALREADY_INITIALIZED {
			return 'MA_DEVICE_ALREADY_INITIALIZED'
		}
		C.MA_DEVICE_NOT_STARTED {
			return 'MA_DEVICE_NOT_STARTED'
		}
		C.MA_DEVICE_NOT_STOPPED {
			return 'MA_DEVICE_NOT_STOPPED'
		}
		// Operation errors.
		C.MA_FAILED_TO_INIT_BACKEND {
			return 'MA_FAILED_TO_INIT_BACKEND '
		}
		C.MA_FAILED_TO_OPEN_BACKEND_DEVICE {
			return 'MA_FAILED_TO_OPEN_BACKEND_DEVICE'
		}
		C.MA_FAILED_TO_START_BACKEND_DEVICE {
			return 'MA_FAILED_TO_START_BACKEND_DEVICE'
		}
		C.MA_FAILED_TO_STOP_BACKEND_DEVICE {
			return 'MA_FAILED_TO_STOP_BACKEND_DEVICE'
		}
		else {
			return 'UNKNOWN'
		}
	}
}
