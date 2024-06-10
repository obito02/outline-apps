// Copyright 2024 The Outline Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package platerrors

// ErrorCode can be used to identify the specific type of a [PlatformError].
// All possible ErrorCodes are defined as constants in this package.
// You can reliably use these values in TypeScript to check for specific errors.
type ErrorCode string

//////////
// Internal error codes
//////////

const (
	// GoError represents a general error in Go that is not a [PlatformError].
	// It is typically the last error in the chain of the causes in a [PlatformError].
	// This error code is for internal use only. You should not use it to create a [PlatformError]
	// in your Go code.
	GoError ErrorCode = "ERR_GOLANG_ERROR"

	// InvalidLogic indicates a development mistake that should be identified and
	// corrected during the development process. It should not be expected to occur in production.
	// Typically this error code is for internal use only. You should not use it to create a
	// [PlatformError] in your Go code.
	InvalidLogic ErrorCode = "ERR_INVALID_LOGIC"
)

//////////
// Common error codes - network
//////////

const (
	// ResolveIPFailed means that we failed to resolve the IP address of a hostname.
	ResolveIPFailed ErrorCode = "ERR_RESOLVE_IP_FAILURE"
)

//////////
// Common error codes - I/O device
//////////

const (
	// SetupTrafficHandlerFailed means we failed to setup the traffic handler for a protocol.
	SetupTrafficHandlerFailed ErrorCode = "ERR_TRAFFIC_HANDLER_SETUP_FAILURE"
)

//////////
// Business logic error codes - proxy server
//////////

const (
	// ProxyServerUnreachable means we failed to establish a connection to a remote server.
	ProxyServerUnreachable ErrorCode = "ERR_PROXY_SERVER_UNREACHABLE"

	// Unauthenticated indicates that the client failed to communicate with a remote server
	// due to the lack of valid authentication credentials.
	Unauthenticated ErrorCode = "ERR_CLIENT_UNAUTHENTICATED"
)

//////////
// Business logic error codes - config
//////////

const (
	// FetchConfigFailed means we failed to fetch a config from a remote location.
	FetchConfigFailed ErrorCode = "ERR_FETCH_REMOTE_CONFIG_FAILURE"

	// IllegalConfig indicates an invalid config to connect to a remote server.
	IllegalConfig ErrorCode = "ERR_ILLEGAL_CONFIG"
)
