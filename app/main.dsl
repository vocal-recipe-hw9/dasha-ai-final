
context {
    input endpoint: string;
    
    nameGlobal: string[] = [];
    Step: string[] = [];
    p: number = 1;
    // declare storage variables here
    output name: string ="";
    output choice: string ="";
}

// declare external functions here 
external function name(name: string): string[];
external function findName(findName: string): string[];

start node root {
    do {
        #connectSafe($endpoint);
        #waitForSpeech(1000);
        #sayText("Hey! Thank you for using recipes helper. How can I help you today?");
        wait *;
    }
    transitions {
    }
}

digression option {
    conditions { on #messageHasIntent("give_option"); }
    do {
        #sayText("You can search recipes by name, and I will tell you the search result.");
        wait*;
    }
    transitions {
    }
}
digression search_name_mode {
    conditions { on #messageHasIntent("search_name"); }
    do {
        #sayText("Okay! You can search recipes by name now.");
        #sayText("What is the recipe name you want to search? ");
        wait*;
    }
    transitions {
    }
}
digression name{
    conditions { on #messageHasData("name"); }
    do 
    {
        set $name = #messageGetData("name", { value: true })[0]?.value??"";
        #sayText("Looking for recipes has " + $name + ", now ");
        var Name = external name($name);
        #sayText("Here is the search result");
        var num: number = 0;
        for (var item in Name){
            set num = num + 1;
            #sayText("      Choice Number " + "  " + num.toString() + "   "+ item + "    ", options: { emotion: "from text: I love you", speed: 0.5});
        }
        set $nameGlobal = Name;
        
        #sayText("Which recipe do you want to make? ");

        wait*;
    }
    transitions {
        find_choice: goto find_choice on #messageHasData("choice");
    }
}
node find_choice {
    do {
        set $choice = #messageGetData("choice", { value: true })[0]?.value??"";
        #sayText("You choose choice number " + $choice + ", now ");

        var choiceNum = $choice.parseNumber();
        set choiceNum = choiceNum - 1;
        var count: number = 0;
        for (var item in $nameGlobal){
            if (count == choiceNum){
                #sayText("I will teach you how to make" + item + " now! ");
                var step = external findName(item);
                set $Step = step;
                set count = count + 1;
            }
            else{
                set count = count + 1;
            }
        }
        var n = 0;
        for(var current in $Step)
        {
            if(n == 0)
                #sayText("Step 1 is " + current);
            set n = n+1;
        }
        wait *;
        
    }
}

digression next_step{
    conditions { on #messageHasIntent("next_step"); }
    do{
        var n = 0;
        for(var current in $Step)
        {
            if(n == $p)
                #sayText("Step" + (n+1).toString() + current);
            set n = n+1;
            if ($p == $Step.length()){
                #sayText("Your recipe is done. Thank you for using recipe helper");
                exit;
            }
        }
        set $p += 1;
        wait *;
    }

}
// node bye_then {
//     do {
//         #sayText("Thank you for using recipes helper! Have a wonderful day. ");
//         exit;
//     }
// }


// node can_help {
//     do {
//         #sayText("Right. How can I help you? ");
//         wait*;
//     }
// }


// digression bye  {
//     conditions { on #messageHasIntent("bye"); }
//     do {
//         #sayText("Thank you for using recipe helper and have a wonderful day! ");
//         exit;
//     }
// }




// additional digressions 
digression @wait {
    conditions { on #messageHasAnyIntent(digression.@wait.triggers)  priority 900; }
    var triggers = ["wait", "wait_for_another_person"];
    var responses: Phrases[] = ["i_will_wait"];
    do {
        for (var item in digression.@wait.responses) {
            #say(item, repeatMode: "ignore");
        }
        #waitingMode(duration: 70000);
        return;
    }
    transitions {
    }
}

digression repeat {
    conditions { on #messageHasIntent("repeat"); }
    do {
        #repeat();
        return;
    }
} 
