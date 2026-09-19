package backend.discord;

import haxe.io.Bytes;
import backend.discord.Pipeline;
import backend.discord.Logs;

import backend.discord.DiscordDefs.UserData;
import backend.discord.DiscordDefs.PresenceData;
import backend.discord.DiscordDefs.ButtonData;

class ClientICP extends backend.discord.Pipeline {
    public static var clientId:String = null;

    public var logger:Logs = null;
    
    public static var pipePath(get, never):String;
    static function get_pipePath():String 
        return "\\\\.\\pipe\\discord-ipc-0";
    public static var payload:Dynamic = null;

    private static var onFinish:(Bool, Dynamic)->Void;

    // When the connection state changes, trigger the callback
    public static var isConnected(default, set):Bool = false;
    static function set_isConnected(b:Bool):Bool {
        if (clientId == null)  return false;
        
        isConnected = b;

        var userData = setData(cachePayload);

        if (onFinish != null) 
            onFinish(b, userData);
        
        return b;
    }

    public function initialized():Bool
        return isConnected;

    public function new(?id:String, ?_onFinish:(Bool, Dynamic)->Void, ?toggle:Bool) {
        if (id != null) clientId = id;
        onFinish = _onFinish;

        logger = new Logs(#if debug true #else false #end);
        if (toggle != null)
            logger.canLog = toggle;

        payload = {
            v: 1, 
            client_id: clientId
        };
    }

    public function initialize():Bool {
        if (clientId == null) return false;
        var packet = Pipeline.encodePacket(0, payload);
        var responseData:Bytes = null;

        if (Pipeline.win32Connect(pipePath)) 
            responseData = Pipeline.win32SendAndRead(packet);


        if (responseData != null) {
            var result = Pipeline.decodePacket(responseData);
            if (result != null && result.payload != null) {
                cachePayload = result.payload.data;
                isConnected = (result.opcode == 1);
            } else 
                isConnected = false;
        } else 
            isConnected = false;
        
        return isConnected;
    }

    public static var cachePayload:Dynamic;
    
    public static function setData(?_payload:Dynamic):UserData {
        if (_payload == null) _payload = cachePayload;
        
        if (_payload != null && _payload.user != null) _payload = _payload.user;
        
        if (_payload == null) return null;

        var temp:UserData = {
            userId: _payload.id != null ? _payload.id : _payload.userId,
            username: _payload.username != null ? _payload.username : "Unknown",
            globalName: _payload.global_name != null ? _payload.global_name : _payload.globalName,
            discriminator: _payload.discriminator != null ? _payload.discriminator : "0",
            avatar: _payload.avatar,
            premiumType: _payload.premium_type != null ? _payload.premium_type : _payload.premiumType,
            bot: _payload.bot == true
        };

        return temp;
    }

    public function sendCommand(cmd:String, args:Dynamic, ?evt:String, ?onSuccess:Void->Void):Void {
        if (!isConnected) {
            logger.log("Cannot send command: Discord IPC is not connected.");
            return;
        }

        var cmdPayload:Dynamic = {
            cmd: cmd,
            args: args,
            nonce: "nonce_" + Date.now().getTime()
        };

        if (evt != null) 
            cmdPayload.evt = evt;

        var packet = Pipeline.encodePacket(1, cmdPayload);
        var responseData:Bytes = null;

        responseData = Pipeline.win32SendAndRead(packet);

        if (onSuccess != null) onSuccess();

        logger.log('Executed command "$cmd"');
        if (responseData != null) {
            var result = Pipeline.decodePacket(responseData);
            logger.log('Payload Response:\n'+result);
        }
    }

    /**
     * Updates the Rich Presence status.
     */
    public function setPresence(activity:Dynamic, ?evt:String, ?onSuccess:Void->Void):Void {
        var currentPid:Int = 0;
        currentPid = Pipeline.win32GetPid();

        var args = {
            pid: currentPid,
            activity: activity
        };

        sendCommand("SET_ACTIVITY", args, evt, onSuccess);
    }

    public function shutdown():Void {
        if (!isConnected) return;

        Pipeline.win32Close();

        isConnected = false;
        logger.log("Discord Rich Presence disconnected.");
    }
}

