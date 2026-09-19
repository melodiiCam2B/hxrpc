package hxrpc;

import lime.app.Application;

import hxrpc.ClientICP;
import hxrpc.DiscordDefs.UserData;
import hxrpc.DiscordDefs.PresenceData;
import hxrpc.DiscordDefs.ButtonData;

using StringTools;
/**
 * wrapper class for the discord RPC!
 */
class DiscordRpc {
    // handles the communication with the api
    public static var client:ClientICP;

    // the user data used to check initilization
    public static var user:UserData;

    // presence data for the payload
    public static var new_presence:PresenceData;

    // back-up presence data for the payload
    public static var old_presence:PresenceData;

    // ID used to interact with the discord api
    public static var clientId:String;

    /**
     * [Description] Starts the Rich Presence status.
     * @param id application id for the rich presence
     * @param toggle if logging is allowed for the library (risks clogging the terminal)
     */
    public static function setup(?id:String, ?toggle:Bool):Void {
        #if (!windows && !cpp)
        Sys.println('You are compiling this library on a non windows target');
        return;
        #end
        if (id != null) clientId = id;
        if (clientId == null) 
            client.logger.log("Discord IPC requires an app ID");
        else {
            new_presence = null;
            old_presence = { 
                state: 'initializing',
                details: 'booting up rpc',

                smallImageKey: 'icon',
                smallImageText: 'temp',

                largeImageKey: 'icon',
                largeImageText: 'temp',
            }
            client = new ClientICP(clientId, onFinish, toggle);
            client.initialize();

            Application.current.window.onClose.add(function() {
			    if(client.initialized()) shutdown();
		    });
        }        
    }

    /**
     * ran on connection to log the payload status
     */
    /**
     * [Description] ran on connection to log the payload status
     * @param connected if the payload was recieved
     * @param user the payload holds user data to confirm it was connected
     */
    public static function onFinish(connected:Bool, user:UserData):Void {
        if (connected && user != null) 
            client.logger.log('Connected successfully to ${user.username} (${user.userId})!');
        else if (!connected && client != null) 
            client.logger.log("Discord IPC failed to connect or user data was invalid.");
        
    }

    /**
     * [Description] run before `changePresence` to take effect, this changes party things
     * @param i party identification
     * @param s current party size
     * @param m max party size
     * @param k party join key
     */
    public static function changeParty(i:String, ?s:Int, ?m:Int, ?k:String) {
        if (client == null) return;
        new_presence = {
            partyId: i,
            partySize: s,
            partyMax: m,
            joinSecret: k
        }

        if (new_presence == null) 
            revertPresence();
            
        updatePresence();
	}

    /**
     * [Description] Updates the Rich Presence status.
     * @param s status text
     * @param d detail text
     * @param skey small image key
     * @param sstr small image text
     * @param lkey large image key
     * @param lstr large image text
     * @param et ending time in seconds
     */
    public static function changePresence(s:String, d:String, ?skey:String, ?sstr:String, ?lkey:String, ?lstr:String, ?et:Float = 0) {
        if (client == null) return;
		var st:Float = 0;
		if (et < 0) st = Date.now().getTime();
		if (et > 0) et = st + et;

        new_presence = {
            state: s,
            details: d,
            smallImageKey: skey,
            smallImageText: sstr,
            largeImageKey: lkey,
            largeImageText: lstr,
            startTimestamp: Std.int(st / 1000),
            endTimestamp: Std.int(et / 1000)
        }

        if (new_presence == null) 
            revertPresence();
            
        updatePresence();
	}

    /**
     * [Description] adds buttons to the rich presence
     * @param fname 
     * @param flink 
     * @param sname 
     * @param slink 
     */
    public static function changeButton(?fname:String, ?flink:String, ?sname:String, ?slink:String) {
        if (client == null) return;
        var buttons:Array<ButtonData> = [];

        if(validate(flink)){
            if (fname != null && flink != null) 
                buttons.push({ label: fname, url: flink });
            else client.logger.log('Invalid arguments flagged: $fname and $flink are null');
        } else client.logger.log('Invalid link flagged: $flink should be https:// || https://');

        if(validate(slink)){
            if (sname != null && slink != null) 
                buttons.push({ label: sname, url: slink });
            else client.logger.log('Invalid arguments flagged: $sname and $slink are null');
        } else client.logger.log('Invalid link flagged: $slink should be https:// || http://');

        new_presence.buttons = buttons;

        if (new_presence == null) 
            revertPresence();
            
        updatePresence();
	}


    // update the presence to the newest state
    public static function updatePresence():Void 
        client.setPresence(new_presence, null, backupPresence);

    // backs up the last presence only if the change was successful
    public static function backupPresence():Void {
        if (old_presence != new_presence)
            old_presence = new_presence;
    }

    // set 'new' to old in case 'new' is null
    public static function revertPresence():Void 
        new_presence = old_presence;
        
    /**
     * Stops the Rich Presence status. and clears the data
     */
    public static function shutdown():Void {
        user = null;
        new_presence = null;
        old_presence = null;
        client.shutdown();
        client = null;
    }

    /**
     * [Description] checks the provided button link has valid formatting
     * @param url link to be checked and validated
     */
    public static function validate(url:String):Bool 
        return url != null && url != "" && (url.indexOf("http://") == 0 || url.indexOf("https://") == 0);
}