package backend.discord;

// method class that prevents unwanted
class Logs {
    public function new(toggle:Bool){
        canLog = toggle;
    }
    public var canLog:Bool = true;
    public function log(s:String) {
        if (canLog != false) Sys.println(s);
    }
}