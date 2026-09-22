allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    val p = this
    if (p.name != "app") {
        p.plugins.withId("com.android.library") {
            try {
                val androidExt = p.extensions.findByName("android")
                if (androidExt != null) {
                    val getSourceSets = androidExt.javaClass.getMethod("getSourceSets")
                    val sourceSets = getSourceSets.invoke(androidExt)
                    if (sourceSets is org.gradle.api.NamedDomainObjectContainer<*>) {
                        val mainSourceSet = sourceSets.findByName("main")
                        if (mainSourceSet != null) {
                            val javaMethod = mainSourceSet.javaClass.methods.firstOrNull { it.name == "getJava" || it.name == "java" }
                            val javaObj = javaMethod?.invoke(mainSourceSet)
                            val srcDirMethod = javaObj?.javaClass?.methods?.firstOrNull { it.name == "srcDir" && it.parameterTypes.size == 1 }
                            srcDirMethod?.invoke(javaObj, "src/main/kotlin")
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
        p.afterEvaluate {
            val androidExt = p.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                    val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                    val current = getNamespace.invoke(androidExt)
                    if (current == null) {
                        val fallbackNamespace = "dev.isar." + p.name.replace("-", "_").replace(":", "_")
                        setNamespace.invoke(androidExt, fallbackNamespace)
                    }
                } catch (e: Exception) {
                    // Ignore
                }
                try {
                    val method = androidExt.javaClass.methods.firstOrNull { 
                        it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1 
                    }
                    if (method != null) {
                        if (method.parameterTypes[0] == Int::class.javaPrimitiveType || method.parameterTypes[0] == java.lang.Integer::class.java) {
                            method.invoke(androidExt, 36)
                        } else if (method.parameterTypes[0] == String::class.java) {
                            method.invoke(androidExt, "android-36")
                        }
                    }
                } catch (e: Exception) {
                    // Ignore
                }
                try {
                    val method = androidExt.javaClass.methods.firstOrNull { 
                        it.name == "compileSdkVersion" && it.parameterTypes.size == 1 
                    }
                    if (method != null) {
                        if (method.parameterTypes[0] == Int::class.javaPrimitiveType || method.parameterTypes[0] == java.lang.Integer::class.java) {
                            method.invoke(androidExt, 36)
                        } else if (method.parameterTypes[0] == String::class.java) {
                            method.invoke(androidExt, "android-36")
                        }
                    }
                } catch (e: Exception) {
                    // Ignore
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
