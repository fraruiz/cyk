create table if not exists GLC (
    START boolean not null,
    LEFT_SYMBOL text not null,
    FIRST_RIGHT_SYMBOL text not null,
    SECOND_RIGHT_SYMBOL text,
    TYPE smallint not null
);


create table if not exists CYK_MATRIX (
    I smallint not null,
    J smallint not null,
    X text not null
);