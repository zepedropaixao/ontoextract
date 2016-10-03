
    function showHideValidation()
    {
		
		var divs,i;
		 divs=document.getElementsByTagName('div');
		 for(i in divs)
		  {
		  if(/validation/.test(divs[i].className))
		   {
			   if(divs[i].style.display!="none")
				{
					divs[i].style.display = "none";
				}
				else
				{
					divs[i].style.display = "inline";
				}
		   }
		  }

       
    }
