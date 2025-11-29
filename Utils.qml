import Quickshell

pragma Singleton

Singleton {
    function formatTime(secs: real): string {
        secs = Math.floor(secs)
        let hrs = Math.floor(secs / (60 * 60))
        secs -= hrs * 60 * 60;
        let mins = Math.floor(secs / 60)
        secs -= mins * 60;
        
        let formattedTime = ""
        if (hrs !== 0) formattedTime += String(hrs).padStart(2, "0") + ":"
        formattedTime += String(mins).padStart(2, "0") + ":" + String(secs).padStart(2, "0")

        return formattedTime
    }
}