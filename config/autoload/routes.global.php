<?php

use Zend\Router\Http\Literal;

return [
    'router' => [
        'routes' => [
            'authentication' => [
                'type' => Literal::class,
                'options' => [
                    'route' => '/login',
                ],
            ],
        ],
    ],
];