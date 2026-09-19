package backend.discord;

import haxe.Json;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

@:cppFileCode('
#include <windows.h>

#undef NO_ERROR
#undef DOMAIN
#undef DELETE
#undef ERROR

static HANDLE g_PipeHandle = INVALID_HANDLE_VALUE;
')

class Pipeline {
    public static function encodePacket(opcode:Int, payload:Dynamic):Bytes {
        var jsonStr = Json.stringify(payload);
        var jsonBytes = Bytes.ofString(jsonStr);

        var output = new BytesOutput();
        output.bigEndian = false;

        output.writeInt32(opcode);
        output.writeInt32(jsonBytes.length);
        output.writeBytes(jsonBytes, 0, jsonBytes.length);

        return output.getBytes();
    }

    public static function decodePacket(data:Bytes):{opcode:Int, payload:Dynamic} {
        if (data == null || data.length < 8) return null;

        var input = new BytesInput(data);
        input.bigEndian = false;

        var opcode = input.readInt32();
        var length = input.readInt32();
        
        var jsonBytes = input.read(length);
        var payload:Dynamic = Json.parse(jsonBytes.toString());

        return {opcode: opcode, payload: payload};
    }

    public static function win32Connect(pipeName:String):Bool {
        var connected:Bool = false;

        untyped __cpp__("
            if (g_PipeHandle != INVALID_HANDLE_VALUE) {
                CloseHandle(g_PipeHandle);
                g_PipeHandle = INVALID_HANDLE_VALUE;
            }

            g_PipeHandle = CreateFileA(
                {0}.c_str(),
                GENERIC_READ | GENERIC_WRITE,
                0,
                NULL,
                OPEN_EXISTING,
                0,
                NULL
            );

            {1} = (g_PipeHandle != INVALID_HANDLE_VALUE);
        ", pipeName, connected);

        return connected;
    }

    public static function win32Write(sendBytes:Bytes):Bool {
        if (sendBytes == null) return false;
        var success:Bool = false;

        untyped __cpp__("
            if (g_PipeHandle != INVALID_HANDLE_VALUE) {
                DWORD bytesWritten = 0;
                const char* rawSendPtr = (const char*){0}->b->Pointer();
                success = WriteFile(g_PipeHandle, rawSendPtr, {0}->length, &bytesWritten, NULL);
            }
        ", sendBytes, success);

        return success;
    }

    public static function win32Read():Bytes {
        var resultBuffer:Bytes = null;

        untyped __cpp__("
            if (g_PipeHandle != INVALID_HANDLE_VALUE) {
                char header[8];
                DWORD bytesRead = 0;

                // Step 1: Read the 8-byte header (4-byte opcode + 4-byte payload length)
                if (ReadFile(g_PipeHandle, header, 8, &bytesRead, NULL) && bytesRead == 8) {
                    int payloadLength = *reinterpret_cast<int*>(header + 4);

                    if (payloadLength >= 0) {
                        int totalFrameSize = 8 + payloadLength;
                        {0} = ::haxe::io::Bytes_obj::alloc(totalFrameSize);

                        // Copy header into Haxe Bytes
                        memcpy({0}->b->Pointer(), header, 8);

                        // Step 2: Loop until full payload is retrieved (fixes >2048 byte limit)
                        int totalPayloadRead = 0;
                        while (totalPayloadRead < payloadLength) {
                            DWORD chunkRead = 0;
                            char* destPtr = (char*){0}->b->Pointer() + 8 + totalPayloadRead;
                            int remaining = payloadLength - totalPayloadRead;

                            if (ReadFile(g_PipeHandle, destPtr, remaining, &chunkRead, NULL) && chunkRead > 0) {
                                totalPayloadRead += chunkRead;
                            } else {
                                break; // Read error or broken pipe
                            }
                        }
                    }
                }
            }
        ", resultBuffer);

        return resultBuffer;
    }

    public static function win32SendAndRead(sendBytes:Bytes):Bytes {
        if (win32Write(sendBytes))
            return win32Read();
        return null;
    }

    public static function win32Close():Void {
        untyped __cpp__("
            if (g_PipeHandle != INVALID_HANDLE_VALUE) {
                CloseHandle(g_PipeHandle);
                g_PipeHandle = INVALID_HANDLE_VALUE;
            }
        ");
    }

    public static function win32GetPid():Int {
        var pid:Int = 0;
        untyped __cpp__("pid = (int)::GetCurrentProcessId();");
        return pid;
    }
}