import type { ComponentType } from 'react';
import type { IconProps } from 'phosphor-react-native';
import { cssInterop } from 'nativewind';

export function iconWithClassName(IconComponent: ComponentType<IconProps>) {
  cssInterop(IconComponent, {
    className: {
      target: 'style',
      nativeStyleToProp: {
        color: 'color',
      },
    },
  });
}

