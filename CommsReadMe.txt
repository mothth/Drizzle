Notes for comms merger (most likely Alduris):
If it has been less than a week since our last commit, please contact us (incandescence_alt) on Discord before the merge so we can confirm that everything is ready.
Copy this into the credits for Community Editor (we will add to this as we add more stuff):

**Of Incandescence** for:
	- `pattern` material type
	- The effects `Pattern Depth`, `Pattern Chaos`
	- Bug-fixes and addition of weighting to `autofit` material type

----

To Merge:
	- Fixed `pattern` material type wrongly discarding tiles that are valid to place
	- Optimised pattern shuffling (The design of the original optimisation assumed the draw tile list wasn't randomised when it is, I don't know how that happened)

Change-Log:
	(We will log what changes had been merged in each update here to keep track)
	- 5.1.0:
		- `pattern` material type
		- `Pattern Depth` effect
		- `Pattern Chaos` effect
		- `autofit` weighting

	- 0.4.65: (???? what and when was 0.4.65)
		Bug-fixes to `autofit`

Current Known Issues:
	- Zero-G Wires are not rendering, but unsure why this is, as our modifications never touched on anything related to that?
	  Could be a bug from the version of comms we are writing upon, or something else entirely.

TODO:
	- For some reason, pattern and autofit weighting work differently. I assume when we wrote weighting for the pattern type,
	  we had changed the design (for the better) and didn't reflect those changes in autofit.