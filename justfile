fmt:
    ls | grep ".qml" --color=never | xargs /usr/lib64/qt6/bin/qmlformat -i

[working-directory: "./audiowiz"]
build-audiowiz:
    clang -Wall main.c -o audiowiz $(pkg-config --cflags --libs libpipewire-0.3) -lm

# compile-shaders:
#    /usr/lib64/qt6/bin/qsb assets/shaders/audioVis.frag -o assets/shaders/audioVis.frag.qsb --qt6