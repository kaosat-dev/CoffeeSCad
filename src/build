({
 
    # Define our base URL - all module paths are relative to this
    # base directory.
    baseUrl: "../app",
 
    # Define our build directory. All files in the base URL will be
    # COPIED OVER into the build directory as part of the
    # concatentation and optimization process. You should use this
    # so you don't override your raw source files.
    dir: "../build",
 
    # Load the RequireJS config() definition from the main.js file.
    # Otherwise, we'd have to redefine all of our paths again here.
    mainConfigFile: "../app/main.js",
 
    # Define the modules to compile.
    modules: [
 
        # When compiling the FAQ module, don't include the modules
        # that have already been included as part of the main
        # compilation (ie. jquery, text, util). This way, we only
        # include the parts of the FAQ dependencies that are unique
        # to the FAQ module (ie. its HTML).
        {
            name: "modules/core/projects/csg/csg",
 
            # If we don't exclude these modules, they will be doubly
            # defined in our main module (since these are ALSO
            # dependencies of our main module).
            ### 
            exclude: [
                "jquery",
                "text",
                "util"
            ]
            ###
        }
 
    ],
 
    # Turn off UglifyJS so that we can view the compiled source
    # files (in order to make sure that we know that the compile
    # is working properly - for debugging only.)
    optimize: "none"
})