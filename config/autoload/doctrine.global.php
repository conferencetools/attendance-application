<?php
return [
    'doctrine' => [
        'connection' => [
            'orm_default' => [
                'driverClass' => Doctrine\DBAL\Driver\PDOSqlite\Driver::class,
                'params' => ['path'   => __DIR__ . '/../../data/db.sqlite'],
            ]
        ]
    ],
];