# What is this? UwU

A mod that says at the top of your screen what you're looking at.


## Api
You can set additional info like so:
```lua
WhatIsThisApi.set_info(pos, "progressbar(50.0)(0xFFFFFF)[Text inside!]\nHello world!")
```

You can read the info like so:
```lua
WhatIsThisApi.get_info(pos)
```

You can also construct a progress bar string via a function like so:
```lua
WhatIsThisApi.get_progress_bar_string(percent, hex, text)

```
## Chat Commands

To hide the pop-up, type this in console:

```
/wituwu
```

Retype to show it again.

## Credits
Released by Kebabmaneater. Credits to Wuzzy for some of the code used in this project, such as the one used for getting the item description. Also credits to the original author of this project Rotfuchs-von-Vulpes. Lastly, credits to Fractality for making the lua spring module used in this project.
