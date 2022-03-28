function J = edgeSobel(I, c, tre)
    Hx = [-1 0 1; -c 0 c; -1 0 1];
    Hy = [1 c 1; 0 0 0; -1 -c -1];
    Jx = convn(double(I), double(Hx), "same");
    Jy = convn(double(I), double(Hy), "same");
    J = uint8(abs(Jx) + abs(Jy)) > tre;
end