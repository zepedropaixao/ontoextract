
    function showHideDiv()
    {
        var divstyle = new String();
        divstyle = document.getElementById("editdiv").style.display;
        if(divstyle.toLowerCase()!="none")
        {
            document.getElementById("editdiv").style.display = "none";
        }
        else
        {
            document.getElementById("editdiv").style.display = "inline";
        }
    }
