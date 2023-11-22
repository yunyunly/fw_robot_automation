from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class CommandLineRequest(_message.Message):
    __slots__ = ["cmd", "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8", "arg9", "arg10", "arg11", "arg12"]
    CMD_FIELD_NUMBER: _ClassVar[int]
    ARG0_FIELD_NUMBER: _ClassVar[int]
    ARG1_FIELD_NUMBER: _ClassVar[int]
    ARG2_FIELD_NUMBER: _ClassVar[int]
    ARG3_FIELD_NUMBER: _ClassVar[int]
    ARG4_FIELD_NUMBER: _ClassVar[int]
    ARG5_FIELD_NUMBER: _ClassVar[int]
    ARG6_FIELD_NUMBER: _ClassVar[int]
    ARG7_FIELD_NUMBER: _ClassVar[int]
    ARG8_FIELD_NUMBER: _ClassVar[int]
    ARG9_FIELD_NUMBER: _ClassVar[int]
    ARG10_FIELD_NUMBER: _ClassVar[int]
    ARG11_FIELD_NUMBER: _ClassVar[int]
    ARG12_FIELD_NUMBER: _ClassVar[int]
    cmd: str
    arg0: str
    arg1: str
    arg2: str
    arg3: str
    arg4: str
    arg5: str
    arg6: str
    arg7: str
    arg8: str
    arg9: str
    arg10: str
    arg11: str
    arg12: str
    def __init__(self, cmd: _Optional[str] = ..., arg0: _Optional[str] = ..., arg1: _Optional[str] = ..., arg2: _Optional[str] = ..., arg3: _Optional[str] = ..., arg4: _Optional[str] = ..., arg5: _Optional[str] = ..., arg6: _Optional[str] = ..., arg7: _Optional[str] = ..., arg8: _Optional[str] = ..., arg9: _Optional[str] = ..., arg10: _Optional[str] = ..., arg11: _Optional[str] = ..., arg12: _Optional[str] = ...) -> None: ...

class CommandLineReply(_message.Message):
    __slots__ = ["stream", "returncode"]
    STREAM_FIELD_NUMBER: _ClassVar[int]
    RETURNCODE_FIELD_NUMBER: _ClassVar[int]
    stream: str
    returncode: int
    def __init__(self, stream: _Optional[str] = ..., returncode: _Optional[int] = ...) -> None: ...
