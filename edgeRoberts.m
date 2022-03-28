function J = edgeRoberts(I, tre)
    Hx = [1 0; 0 -1];
    Hy = [0 1; -1 0];
    Jx = convn(double(I), double(Hx), "same");
    Jy = convn(double(I), double(Hy), "same");
    J = uint8(abs(Jx) + abs(Jy)) > tre;
end