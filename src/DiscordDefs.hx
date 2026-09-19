package backend.discord;

// we store the typedefs here for easy access
typedef UserData = {
    var userId:String;
    var username:String;
    var globalName:String;
    var discriminator:String;
    var avatar:String;
    var premiumType:Null<Int>;
    var bot:Null<Bool>;
}

typedef PresenceData = {
    var ?state:String;
    var ?details:String;

    var ?smallImageKey:String;
    var ?smallImageText:String;

    var ?largeImageKey:String;
    var ?largeImageText:String;

    var ?startTimestamp:Int;
    var ?endTimestamp:Int;

    var ?partyId:String;
    var ?partySize:Int;
    var ?partyMax:Int;
    var ?joinSecret:String;

    var ?buttons:Array<ButtonData>;
}

typedef ButtonData = {
    var label:String;
    var url:String;
}

// class that masks as a typedef?
class DiscordDefs {
    public function new() {
        
    }
}