<?php

use Doctrine\DBAL\Driver\PDOMySql\Driver as PDOMySqlDriver;

return [
    'conferencetools' => [
        'payment_providers' => [
            'stripe' => [
                'secret_key' => getenv('STRIPE_SECRET_KEY'),
                'publishable_key' => getenv('STRIPE_PUBLISHABLE_KEY'),
            ]
        ]
    ],
    'doctrine' => [
        'connection' => [
            // default connection name
            'orm_default' => [
                'driverClass' => PDOMySqlDriver::class,
                'params' => [
                    'host'     => getenv('DB_HOST'),
                    'port'     => getenv('DB_PORT'),
                    'user'     => getenv('DB_USER'),
                    'password' => getenv('DB_PASS'),
                    'dbname'   => getenv('DB_NAME'),
                ],
            ],
        ],
    ],
    'mail' => [
        'type' => 'smtp',
        'options' => [
            'host' => getenv('MAIL_HOST'),
            'port' => getenv('MAIL_PORT'),
            'connection_class' => getenv('MAIL_AUTH_MODE'),
            'connection_config' => [
                'username' => getenv('MAIL_USER'),
                'password' => getenv('MAIL_PASS'),
                'ssl' => getenv('MAIL_ENCRYPTION'),
            ],
        ],
    ],

];