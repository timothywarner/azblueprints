@{
    ExcludeRules=@(
        'PSUseDeclaredVarsMoreThanAssignments', # This rule sometimes has false positives when nesting
        'PSAvoidGlobalVars' # We need global variables for our test variables in the module scope
        'PSReviewUnusedParameter' # Parameters are Delcared and used, but reports they are not.
	)
}