fmt:
    ls | grep ".qml" --color=never | xargs /usr/lib64/qt6/bin/qmlformat -i

[working-directory: "./audiowiz"]
build-audiowiz:
    clang -Wall main.c -o audiowiz $(pkg-config --cflags --libs libpipewire-0.3) -lm